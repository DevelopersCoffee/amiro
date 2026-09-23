package com.developerscoffee.amiro_app

import android.nfc.cardemulation.HostApduService
import android.os.Bundle

/**
 * Emulates a standards-compliant NFC Forum **Type 4 Tag** carrying the
 * current share URI as an NDEF Text record, so another device — Android
 * (via `nfc_manager`'s `NdefAndroid`, see `packages/nfc/lib/src/nfc_reader.dart`)
 * or iOS (via Core NFC) — can tap and read it as an ordinary NDEF tag.
 *
 * The URI is set/cleared via [AmiroHceService.currentPayload], written by
 * [MainActivity]'s method channel handler (see writeIdentityPayload /
 * stopEmulating). This service has no direct Flutter engine access — it's
 * a plain Android component the OS starts on tag-reader polling, so state
 * is passed through this static field rather than a channel call from
 * inside the service itself.
 *
 * Implements the minimal subset of the Type 4 Tag Technical Specification
 * needed for a read-only tag: SELECT (by the NDEF Tag Application AID,
 * then by file ID) and READ BINARY, against a fixed Capability Container
 * file and a single NDEF file. There is no unit-test harness for this —
 * it's native, protocol-level, HCE code that only a real reader device can
 * fully exercise (see the Task 9 device spike notes in the design spec);
 * the constants and framing below are commented against the spec instead.
 */
class AmiroHceService : HostApduService() {

    /** Which file, if any, the reader most recently SELECTed. */
    private enum class SelectedFile { NONE, CAPABILITY_CONTAINER, NDEF }

    private var selectedFile: SelectedFile = SelectedFile.NONE

    companion object {
        /** The URI currently being shared, or null if not emulating. */
        @Volatile
        var currentPayload: String? = null

        // --- NFC Forum Type 4 Tag protocol constants ---
        // These are easy to get subtly wrong and this plan has no prior
        // art for HCE Type 4 Tag emulation elsewhere in the repo to crib
        // from, so each one is commented against the NFC Forum Type 4 Tag
        // Technical Specification (T4T) it comes from.

        /**
         * The standard NDEF Tag Application AID (T4T §3.2, Table 3). This
         * is a fixed, spec-defined value shared by every Type 4 Tag
         * implementation — it identifies "this is an NDEF-readable tag
         * application", not anything app-specific. Do not confuse with the
         * file IDs below, which are also spec-fixed but select a *file*
         * within this already-selected application.
         */
        private val NDEF_APP_AID = byteArrayOf(
            0xD2.toByte(), 0x76, 0x00, 0x00, 0x85.toByte(), 0x01, 0x01
        )

        /** Well-known Capability Container file ID (T4T §3.5, Table 4). */
        private val CC_FILE_ID = byteArrayOf(0xE1.toByte(), 0x03)

        /**
         * NDEF file ID. The spec leaves the exact value application-defined
         * (T4T §3.6) as long as it's advertised via the CC's NDEF File
         * Control TLV, which [CC_FILE_BYTES] below does — E104 is simply
         * the conventional value essentially every Type 4 Tag
         * implementation uses.
         */
        private val NDEF_FILE_ID = byteArrayOf(0xE1.toByte(), 0x04)

        private const val INS_SELECT = 0xA4
        private const val INS_READ_BINARY = 0xB0

        private val STATUS_SUCCESS = byteArrayOf(0x90.toByte(), 0x00)
        private val STATUS_FILE_NOT_FOUND = byteArrayOf(0x6A, 0x82.toByte())
        private val STATUS_WRONG_LENGTH = byteArrayOf(0x67, 0x00)
        private val STATUS_INS_NOT_SUPPORTED = byteArrayOf(0x6D, 0x00)

        /**
         * Maximum bytes returned in a single READ BINARY response,
         * advertised to the reader via the CC's MLe field below (T4T
         * §5.1.2). This only caps the size of one response chunk, not the
         * total NDEF file size — a reader pages through a larger file with
         * multiple READ BINARY calls at increasing offsets, which
         * [handleReadBinary] supports.
         */
        private const val MAX_READ_BINARY_LENGTH = 0xF6 // 246 bytes

        /**
         * The maximum NDEF file size this tag advertises capacity for
         * (2048 bytes) — generous enough for an `amiro://share` URI whose
         * payload includes a base64-encoded avatar definition, which can
         * be the largest field by far. The *actual* current message is
         * always much smaller and is framed with its own NLEN prefix (see
         * [buildNdefFileBytes]); this is only the advertised ceiling.
         */
        private const val NDEF_FILE_MAX_SIZE = 0x0800 // 2048

        /**
         * Capability Container file contents (T4T §5.1.2). Fixed and
         * precomputed since it never changes for this app:
         *
         * - CCLEN (2 bytes): length of this CC file itself (15 bytes).
         * - Mapping Version (1 byte): 0x20 = version 2.0.
         * - MLe (2 bytes): max R-APDU data size for READ BINARY.
         * - MLc (2 bytes): max C-APDU data size for UPDATE BINARY. This
         *   tag is read-only and never actually services an UPDATE
         *   BINARY, but the NFC Forum Type 4 Tag spec still requires MLc
         *   to be in range 0x0001-0xFFFF even for a read-only tag — a
         *   0x0000 value is out of spec and risks Android's own NDEF tag
         *   detection (`rw_t4t` in libnfc-nci) rejecting the tag before
         *   this app ever gets a chance to read it. 0x00FF is used as a
         *   spec-valid placeholder.
         * - NDEF File Control TLV (T4T §5.1.2, Table 7): tag 0x04, length
         *   6, then the NDEF file's ID, max size, and read/write access
         *   bytes (0x00 = read allowed, 0xFF = write denied).
         */
        private val CC_FILE_BYTES = byteArrayOf(
            0x00, 0x0F, // CCLEN = 15
            0x20, // Mapping Version 2.0
            0x00, MAX_READ_BINARY_LENGTH.toByte(), // MLe
            0x00, 0xFF.toByte(), // MLc (spec-valid placeholder; no write support)
            0x04, 0x06, // NDEF File Control TLV: tag=0x04, length=6
            NDEF_FILE_ID[0], NDEF_FILE_ID[1],
            (NDEF_FILE_MAX_SIZE shr 8).toByte(), (NDEF_FILE_MAX_SIZE and 0xFF).toByte(),
            0x00, // read access granted
            0xFF.toByte(), // write access denied
        )

        /**
         * Builds a single-record NDEF message wrapping [text] as an NFC
         * Forum well-known Text record (RTD_TEXT, type `'T'`) — the exact
         * format `decodeNdefTextPayload` on the Dart side expects (see
         * `packages/nfc/lib/src/nfc_reader.dart`): a status byte (low 6
         * bits = IANA language code length, high bit = text encoding, 0
         * for UTF-8) followed by the language code, then the raw text.
         *
         * Uses the NDEF short-record format (1-byte payload length) when
         * the payload fits in a byte, and the long-record format (4-byte
         * big-endian payload length) otherwise — a share payload carrying
         * an avatar definition can comfortably exceed 255 bytes.
         */
        internal fun buildNdefTextMessage(text: String): ByteArray {
            val languageCode = "en".toByteArray(Charsets.US_ASCII)
            val textBytes = text.toByteArray(Charsets.UTF_8)
            // Bit 7 (UTF-16 flag) unset = UTF-8; low 6 bits = language code length.
            val statusByte = languageCode.size.toByte()
            val payload = byteArrayOf(statusByte) + languageCode + textBytes

            val typeField = byteArrayOf('T'.code.toByte())
            val shortRecord = payload.size <= 0xFF

            // Record header flag bits: MB(1) ME(1) CF(0) SR IL(0) TNF(001).
            // MB/ME = this is both the first and last (only) record in the
            // message; CF = not chunked; IL = no ID field; TNF 001 =
            // well-known type.
            val header: Byte
            val lengthField: ByteArray
            if (shortRecord) {
                header = 0xD1.toByte() // SR=1
                lengthField = byteArrayOf(payload.size.toByte())
            } else {
                header = 0xC1.toByte() // SR=0
                lengthField = byteArrayOf(
                    (payload.size shr 24).toByte(),
                    (payload.size shr 16).toByte(),
                    (payload.size shr 8).toByte(),
                    payload.size.toByte(),
                )
            }

            return byteArrayOf(header, typeField.size.toByte()) + lengthField + typeField + payload
        }
    }

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        if (commandApdu == null || commandApdu.size < 4) return STATUS_FILE_NOT_FOUND

        val ins = commandApdu[1].toInt() and 0xFF
        val p1 = commandApdu[2]
        val p2 = commandApdu[3]

        return when (ins) {
            INS_SELECT -> handleSelect(p1, p2, commandApdu)
            INS_READ_BINARY -> handleReadBinary(p1, p2, commandApdu)
            else -> STATUS_INS_NOT_SUPPORTED
        }
    }

    /**
     * Handles both SELECT forms a Type 4 Tag reader uses:
     * - SELECT by name/AID (P1=0x04): select the NDEF Tag Application.
     * - SELECT by file ID (P1=0x00): select the CC file or the NDEF file,
     *   once already inside the NDEF application.
     */
    private fun handleSelect(p1: Byte, p2: Byte, apdu: ByteArray): ByteArray {
        val lc = apdu.getOrNull(4)?.toInt()?.and(0xFF) ?: return STATUS_WRONG_LENGTH
        if (apdu.size < 5 + lc) return STATUS_WRONG_LENGTH
        val field = apdu.copyOfRange(5, 5 + lc)

        if (p1 == 0x04.toByte()) {
            return if (field.contentEquals(NDEF_APP_AID)) {
                selectedFile = SelectedFile.NONE
                STATUS_SUCCESS
            } else {
                STATUS_FILE_NOT_FOUND
            }
        }

        if (p1 == 0x00.toByte() && lc == 2) {
            return when {
                field.contentEquals(CC_FILE_ID) -> {
                    selectedFile = SelectedFile.CAPABILITY_CONTAINER
                    STATUS_SUCCESS
                }
                field.contentEquals(NDEF_FILE_ID) -> {
                    selectedFile = SelectedFile.NDEF
                    STATUS_SUCCESS
                }
                else -> STATUS_FILE_NOT_FOUND
            }
        }

        return STATUS_FILE_NOT_FOUND
    }

    /**
     * Serves a chunk of whichever file is currently selected, honoring the
     * requested offset (P1/P2, big-endian) and Le (requested length, where
     * a 0 byte means 256 per ISO 7816-4).
     */
    private fun handleReadBinary(p1: Byte, p2: Byte, apdu: ByteArray): ByteArray {
        val fileBytes = when (selectedFile) {
            SelectedFile.CAPABILITY_CONTAINER -> CC_FILE_BYTES
            SelectedFile.NDEF -> buildNdefFileBytes()
            SelectedFile.NONE -> return STATUS_FILE_NOT_FOUND
        }

        val offset = ((p1.toInt() and 0xFF) shl 8) or (p2.toInt() and 0xFF)
        val requestedLe = apdu.getOrNull(4)?.toInt()?.and(0xFF) ?: 0
        val le = if (requestedLe == 0) 256 else requestedLe

        if (offset > fileBytes.size) return STATUS_FILE_NOT_FOUND
        val end = minOf(fileBytes.size, offset + le)
        return fileBytes.copyOfRange(offset, end) + STATUS_SUCCESS
    }

    /**
     * Builds the NDEF file's full contents: a 2-byte big-endian NLEN
     * length prefix (T4T §5.2) followed by the NDEF message itself.
     * Returns NLEN=0 with no message when nothing is currently being
     * shared (`currentPayload == null`) — a valid, spec-compliant "empty
     * tag" state rather than an error, since SELECT/READ BINARY on the
     * NDEF file must succeed regardless of whether Share is active.
     */
    private fun buildNdefFileBytes(): ByteArray {
        val payload = currentPayload
        val message = if (payload == null) ByteArray(0) else buildNdefTextMessage(payload)
        val nlen = byteArrayOf((message.size shr 8).toByte(), (message.size and 0xFF).toByte())
        return nlen + message
    }

    override fun onDeactivated(reason: Int) {
        // Reset per-session selection state, but currentPayload persists
        // until explicitly cleared via stopEmulating(), so re-tapping
        // without re-triggering Share still works.
        selectedFile = SelectedFile.NONE
    }
}
