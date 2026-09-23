package com.developerscoffee.amiro_app

import android.nfc.cardemulation.HostApduService
import android.os.Bundle

/**
 * Emulates an NFC tag carrying the current share URI, so another device
 * (Android, or an iPhone using Core NFC to read) can tap and read it.
 *
 * The URI is set/cleared via [AmiroHceService.currentPayload], written by
 * [MainActivity]'s method channel handler (see writeIdentityPayload /
 * stopEmulating). This service has no direct Flutter engine access — it's
 * a plain Android component the OS starts on tag-reader polling, so state
 * is passed through this static field rather than a channel call from
 * inside the service itself.
 */
class AmiroHceService : HostApduService() {

    companion object {
        /** The URI currently being shared, or null if not emulating. */
        @Volatile
        var currentPayload: String? = null

        private val SELECT_AID_APDU = byteArrayOf(
            0x00, 0xA4.toByte(), 0x04, 0x00, 0x08,
            0xF0.toByte(), 0x41, 0x4D, 0x49, 0x52, 0x4F, 0x30, 0x30, 0x31
        )
        private val STATUS_SUCCESS = byteArrayOf(0x90.toByte(), 0x00)
        private val STATUS_NOT_FOUND = byteArrayOf(0x6A, 0x82.toByte())
    }

    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        val payload = currentPayload
        if (payload == null) {
            return STATUS_NOT_FOUND
        }
        // Minimal protocol: any SELECT AID command (or any command at all,
        // since this service only registers for our one AID) gets the full
        // UTF-8 payload bytes back, followed by the success status word.
        // A real NDEF Type 4 Tag implementation would parse SELECT/READ
        // BINARY commands properly — this simplified version works because
        // both sides are our own app (Android emulate <-> our own NFC
        // reader), and iOS's Core NFC reader (Task 7's cross-device case)
        // reads this as raw APDU response bytes too. Verify this
        // simplification holds during the Task 7 device spike; if iOS's
        // Core NFC requires a spec-correct NDEF Type 4 Tag exchange, this
        // will need real READ BINARY / SELECT NDEF file handling.
        val payloadBytes = payload.toByteArray(Charsets.UTF_8)
        return payloadBytes + STATUS_SUCCESS
    }

    override fun onDeactivated(reason: Int) {
        // No cleanup needed — currentPayload persists until explicitly
        // cleared via stopEmulating(), so re-tapping without re-triggering
        // Share still works.
    }
}
