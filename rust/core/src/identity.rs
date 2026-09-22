use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Identity {
    pub id: String,
    pub display_name: String,
    pub username: String,
    pub bio: Option<String>,
    pub mobile: Option<String>,
    pub email: Option<String>,
    pub x_handle: Option<String>,
    pub instagram_handle: Option<String>,
    pub website: Option<String>,
}

#[derive(Debug, PartialEq)]
pub enum IdentityError {
    EmptyDisplayName,
    EmptyUsername,
    UsernameHasSpaces,
}

impl Identity {
    pub fn new(id: String, display_name: String, username: String) -> Result<Self, IdentityError> {
        let identity = Identity {
            id,
            display_name,
            username,
            bio: None,
            mobile: None,
            email: None,
            x_handle: None,
            instagram_handle: None,
            website: None,
        };
        identity.validate()?;
        Ok(identity)
    }

    pub fn validate(&self) -> Result<(), IdentityError> {
        if self.display_name.trim().is_empty() {
            return Err(IdentityError::EmptyDisplayName);
        }
        if self.username.trim().is_empty() {
            return Err(IdentityError::EmptyUsername);
        }
        if self.username.contains(' ') {
            return Err(IdentityError::UsernameHasSpaces);
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_valid_identity_succeeds() {
        let identity = Identity::new("id-1".into(), "Uday".into(), "uday".into()).unwrap();
        assert_eq!(identity.display_name, "Uday");
        assert_eq!(identity.username, "uday");
        assert_eq!(identity.bio, None);
    }

    #[test]
    fn new_with_empty_display_name_fails() {
        let result = Identity::new("id-1".into(), "".into(), "uday".into());
        assert_eq!(result, Err(IdentityError::EmptyDisplayName));
    }

    #[test]
    fn new_with_empty_username_fails() {
        let result = Identity::new("id-1".into(), "Uday".into(), "".into());
        assert_eq!(result, Err(IdentityError::EmptyUsername));
    }

    #[test]
    fn username_with_spaces_fails() {
        let result = Identity::new("id-1".into(), "Uday".into(), "uday chauhan".into());
        assert_eq!(result, Err(IdentityError::UsernameHasSpaces));
    }

    #[test]
    fn serde_round_trip_preserves_all_fields() {
        let mut identity = Identity::new("id-1".into(), "Uday".into(), "uday".into()).unwrap();
        identity.bio = Some("Software Engineer".into());
        identity.email = Some("coffee.devloper@gmail.com".into());

        let json = serde_json::to_string(&identity).unwrap();
        let restored: Identity = serde_json::from_str(&json).unwrap();

        assert_eq!(identity, restored);
    }
}
