/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Firebase
import Reactor
import Marshal

/// Empty protocol to help categorize events
public protocol FirebaseAuthenticationEvent: Event { }

/**
 An error that occurred authenticating with Firebase.
 
 - `LogInMissingUserId`:    The auth payload contained no user id
 - `SignUpFailedLogIn`:     The user was signed up, but could not be logged in
 - `CurrentUserNotFound`:   The data for the current user could not be found
 */
public enum FirebaseAuthenticationError: Error {
    case logInMissingUserId
    case signUpFailedLogIn
    case currentUserNotFound
}

/**
 An action type regarding user authentication
 
 - `PasswordChanged`:   The password for the user was successfully changed
 - `EmailChanged`:      The email for the user was successfully changed
 - `PasswordReset`:     The user was sent a reset password email
 - `EmailVerificationSent`: The user was an email confirmation email
 */
public enum FirebaseAuthenticationAction {
    case passwordChanged
    case emailChanged
    case passwordReset
    case emailVerificationSent
}


// MARK: - User events

/**
 Event indicating that the user has just successfully logged in with email and password.
 - **userId**: The id of the user
 - **emailVerified**: Status of user’s email verification
 - **email**: Email address of user
 */
public struct UserLoggedIn: FirebaseAuthenticationEvent {
    public var userId: String
    public var emailVerified: Bool
    public var email: String?
    
    public init(userId: String, emailVerified: Bool = false, email: String?) {
        self.userId = userId
        self.emailVerified = emailVerified
        self.email = email
    }
}

/**
 Event indicating that the user has just successfully signed up.
 - **userId**: The id of the user
 - **email**: Email address of user
 */
public struct UserSignedUp: FirebaseAuthenticationEvent {
    public var userId: String
    public var email: String
    
    public init(userId: String, email: String) {
        self.userId = userId
        self.email = email
    }
}

/// General event regarding user authentication
/// - **event**: The authentication event that occurred
public struct UserAuthenticationEvent: FirebaseAuthenticationEvent {
    public var action: FirebaseAuthenticationAction
    
    public init(action: FirebaseAuthenticationAction) {
        self.action = action
    }
}

/// Event indicating that a failure occurred during authentication.
/// - **error**: The error that produced the failure
public struct UserAuthFailed: FirebaseSeriousErrorEvent {
    public var error: Error
    
    public init(error: Error) {
        self.error = error
    }
}

/**
 Event indicating that the user is properly authenticated.
 - **userId**: The id of the authenticated user
 - **emailVerified**: Indicating if the user's email is verified
 */
public struct UserIdentified: FirebaseAuthenticationEvent {
    public var userId: String
    public var emailVerified: Bool
    public init(userId: String, emailVerified: Bool = false) {
        self.userId = userId
        self.emailVerified = emailVerified
    }
}

/// Event indicating that the user has been unauthenticated.
public struct UserLoggedOut: FirebaseAuthenticationEvent {
    public init() { }
}

/// Event indication an error when sending email verification.
/// - **error**: The error that occurred
public struct EmailVerificationError: FirebaseMinorErrorEvent {
    public var error: Error
    
    public init(error: Error) {
        self.error = error
    }
}
