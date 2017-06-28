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
public protocol FirebaseReactorAuthenticationEvent: Event { }

/**
 An error that occurred authenticating with Firebase.
 
 - `LogInMissingUserId`:    The auth payload contained no user id
 - `SignUpFailedLogIn`:     The user was signed up, but could not be logged in
 - `CurrentUserNotFound`:   The data for the current user could not be found
 */
public enum FirebaseReactorAuthenticationError: Error {
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
public enum FirebaseReactorAuthenticationAction {
    case passwordChanged
    case emailChanged
    case passwordReset
    case emailVerificationSent
}

public extension FirebaseReactorAccess {
    
    /// Attempts to retrieve the user's authentication id. If successful, it is returned.
    /// - returns: The user's authentication id, or nil if not authenticated
    public func getUserId() -> String? {
        guard let currentApp = currentApp else { return nil}
        let auth = Auth.auth(app: currentApp)
        guard let user = auth.currentUser else { return nil }
        return user.uid
    }
    
    /// Attempts to retrieve user's email verified status.
    /// - returns: `true` if email has been verified, otherwise `false`.
    public func getUserEmailVerified() -> Bool {
        guard let currentApp = currentApp else { return false }
        let auth = Auth.auth(app: currentApp)
        guard let user = auth.currentUser else { return false }
        return user.isEmailVerified
    }
    
}

/// Reloads the current user object. This is useful for checking whether `emailVerified` is now true.
/// - **app**: `FirebaseApp` - The current FirebaseApp
public struct ReloadCurrentUser<T: State>: Command {
    
    var app: FirebaseApp?
    
    public func execute(state: T, core: Core<T>) {
        guard let app = app else { return }
        let auth = Auth.auth(app: app)
        guard let user = auth.currentUser else { return }
        user.reload { error in
            if let error = error {
                core.fire(event: ReactorUserAuthFailed(error: error))
            } else {
                core.fire(event: ReactorUserIdentified(userId: user.uid, emailVerified: user.isEmailVerified))
            }
        }
    }
    
}

/**
 Sends verification email to specified user, or current user if not specified.
 - **user**: `User` - User for which the email will be sent if not the current user
 - **app**: `FirebaseApp` - The current FirebaseApp
 */
public struct SendEmailVerification<T: State>: Command {
    
    var user: User?
    var app: FirebaseApp?
    
    public init(for user: User? = nil, app: FirebaseApp? = FirebaseApp.app()) {
        self.user = user
        self.app = app
    }
    
    public func execute(state: T, core: Core<T>) {
        let emailUser: User
        if let user = user {
            emailUser = user
        } else {
            guard let app = app else { return }
            let auth = Auth.auth(app: app)
            guard let user = auth.currentUser else { return }
            emailUser = user
        }
        emailUser.sendEmailVerification { error in
            if let error = error {
                core.fire(event: ReactorEmailVerificationError(error: error))
            } else {
                core.fire(event: ReactorUserAuthenticationEvent(action: .emailVerificationSent))
            }
        }
    }
    
}

/**
 Authenticates the user with email address and password. If successful, fires an event
 with the user’s id (`UserLoggedIn`), otherwise fires a failed event with an error
 (`UserAuthFailed`).
 
 - **email**:    The user’s email address
 - **password**: The user’s password
 */
public struct LogInUser<T: State>: Command {
    
    var email: String
    var password: String
    var app: FirebaseApp?
    
    public init(email: String, password: String, app: FirebaseApp?) {
        self.email = email
        self.password = password
        self.app = app
    }
    
    public func execute(state: T, core: Core<T>) {
        guard let app = app else { return }
        let auth = Auth.auth(app: app)
        auth.signIn(withEmail: email, password: password) { user, error in
            if let error = error {
                core.fire(event: ReactorUserAuthFailed(error: error))
            } else if let user = user {
                core.fire(event: ReactorUserLoggedIn(userId: user.uid, emailVerified: user.isEmailVerified, email: self.email))
            } else {
                core.fire(event: ReactorUserAuthFailed(error: FirebaseAuthenticationError.logInMissingUserId))
            }
        }
    }
    
}

/**
 Creates a user with the email address and password.
 
 - **email**:    The user’s email address
 - **password**: The user’s password
 - **app**: `FirebaseApp` - the current firebase app
 - **completion**: Optional closure that takes in the new user's `uid` if possible
 */
public struct SignUpUser<T: State>: Command {
    
    var email: String
    var password: String
    var app: FirebaseApp?
    var completion: ((String?) -> Void)?
    
    public init(email: String, password: String, app: FirebaseApp?, completion: ((String?) -> Void)?) {
        self.email = email
        self.password = password
        self.app = app
        self.completion = completion
    }
    
    public func execute(state: T, core: Core<T>) {
        guard let app = app else { return }
        let auth = Auth.auth(app: app)
        auth.createUser(withEmail: email, password: password) { user, error in
            if let error = error {
                core.fire(event: ReactorUserAuthFailed(error: error))
                self.completion?(nil)
            } else if let user = user {
                core.fire(event: ReactorUserSignedUp(userId: user.uid, email: self.email))
                if let completion = self.completion {
                    completion(user.uid)
                } else {
                    core.fire(event: ReactorUserLoggedIn(userId: user.uid, email: self.email))
                }
            } else {
                core.fire(event: ReactorUserAuthFailed(error: FirebaseAuthenticationError.signUpFailedLogIn))
                self.completion?(nil)
            }
        }
    }
    
}

/**
 Change a user’s password.
 - **newPassword**:  The new password for the user
 - **app**: `FirebaseApp` - The current FirebaseApp
 */
public struct ChangeUserPassword<T: State>: Command {
    
    var newPassword: String
    var app: FirebaseApp?
    
    public init(newPassword: String, app: FirebaseApp?) {
        self.newPassword = newPassword
        self.app = app
    }
    
    public func execute(state: T, core: Core<T>) {
        guard let app = app else { return }
        let auth = Auth.auth(app: app)
        guard let user = auth.currentUser else {
            core.fire(event: ReactorUserAuthFailed(error: FirebaseAuthenticationError.currentUserNotFound))
            return
        }
        user.updatePassword(to: newPassword) { error in
            if let error = error {
                core.fire(event: ReactorUserAuthFailed(error: error))
            } else {
                core.fire(event: ReactorUserAuthenticationEvent(action: FirebaseReactorAuthenticationAction.passwordChanged))
            }
        }
    }
    
}

/**
 Change a user’s email address.
 
 - **email**: `String` - The new email address for the user
 - **app**: `FirebaseApp` - The current FirebaseApp
 */
public struct ChangeUserEmail<T: State>: Command {
    
    var email: String
    var app: FirebaseApp?
    
    public init(email: String, app: FirebaseApp?) {
        self.email = email
        self.app = app
    }
    
    public func execute(state: T, core: Core<T>) {
        guard let app = app else { return }
        let auth = Auth.auth(app: app)
        guard let user = auth.currentUser else {
            core.fire(event: ReactorUserAuthFailed(error: FirebaseAuthenticationError.currentUserNotFound))
            return
        }
        user.updateEmail(to: email) { error in
            if let error = error {
                core.fire(event: ReactorUserAuthFailed(error: error))
            } else {
                core.fire(event: ReactorUserAuthenticationEvent(action: FirebaseReactorAuthenticationAction.emailChanged))
            }
        }
    }
    
}
/**
 Send the user a reset password email.
 - **email**: The user’s email address
 - **app**: `FirebaseApp` - The current FirebaseApp
 */
public struct ResetPassword<T: State>: Command {
    
    var email: String
    var app: FirebaseApp?
    
    public init(email: String, app: FirebaseApp? = FirebaseApp.app()) {
        self.email = email
        self.app = app
    }
    
    public func execute(state: T, core: Core<T>) {
        guard let app = app else { return }
        let auth = Auth.auth(app: app)
        auth.sendPasswordReset(withEmail: email) { error in
            if let error = error {
                core.fire(event: ReactorUserAuthFailed(error: error))
            } else {
                core.fire(event: ReactorUserAuthenticationEvent(action: FirebaseReactorAuthenticationAction.passwordReset))
            }
        }
    }
    
}

/// Unauthenticates the current user and fires a `UserLoggedOut` event.
/// - **app**: `FirebaseApp` - The current FirebaseApp
public struct LogOutUser<T: State>: Command {
    
    var app: FirebaseApp?
    
    public init(app: FirebaseApp? = FirebaseApp.app()) {
        self.app = app
    }
    
    public func execute(state: T, core: Core<T>) {
        do {
            guard let app = app else { return }
            let auth = Auth.auth(app: app)
            try auth.signOut()
            core.fire(event: ReactorUserLoggedOut())
        } catch {
            core.fire(event: ReactorUserAuthFailed(error: error))
        }
    }
    
}


// MARK: - User events

/**
 Event indicating that the user has just successfully logged in with email and password.
 - **userId**: The id of the user
 - **emailVerified**: Status of user’s email verification
 - **email**: Email address of user
 */
public struct ReactorUserLoggedIn: FirebaseReactorAuthenticationEvent {
    public var userId: String
    public var emailVerified: Bool
    public var email: String
    
    public init(userId: String, emailVerified: Bool = false, email: String) {
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
public struct ReactorUserSignedUp: FirebaseReactorAuthenticationEvent {
    public var userId: String
    public var email: String
    
    public init(userId: String, email: String) {
        self.userId = userId
        self.email = email
    }
}

/// General event regarding user authentication
/// - **event**: The authentication event that occurred
public struct ReactorUserAuthenticationEvent: FirebaseReactorAuthenticationEvent {
    public var action: FirebaseReactorAuthenticationAction
    
    public init(action: FirebaseReactorAuthenticationAction) {
        self.action = action
    }
}

/// Event indicating that a failure occurred during authentication.
/// - **error**: The error that produced the failure
public struct ReactorUserAuthFailed: FirebaseSeriousErrorEvent {
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
public struct ReactorUserIdentified: FirebaseReactorAuthenticationEvent {
    public var userId: String
    public var emailVerified: Bool
    public init(userId: String, emailVerified: Bool = false) {
        self.userId = userId
        self.emailVerified = emailVerified
    }
}

/// Event indicating that the user has been unauthenticated.
public struct ReactorUserLoggedOut: FirebaseReactorAuthenticationEvent {
    public init() { }
}

/// Event indication an error when sending email verification.
/// - **error**: The error that occurred
public struct ReactorEmailVerificationError: FirebaseMinorErrorEvent {
    public var error: Error
    
    public init(error: Error) {
        self.error = error
    }
}
