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

public protocol FirebaseReactorAccess {
    
    /// The base ref for your Firebase app
    var ref: DatabaseReference { get }
    var currentApp: FirebaseApp? { get }
    
    func newObjectId() -> String
    func createObject<T>(at ref: DatabaseReference, createNewChildId: Bool, removeId: Bool, parameters: JSONObject, core: Core<T>)
    
    func updateObject<T>(at ref: DatabaseReference, parameters: JSONObject, core: Core<T>)
    func updateObjectDirectly<T>(at ref: DatabaseReference, parameters: JSONObject, core: Core<T>)
    func removeObject<T>(at ref: DatabaseReference, core: Core<T>)
    func getObject<T>(at objectQuery: DatabaseQuery, core: Core<T>, completion: @escaping (_ objectJSON: JSONObject?) -> Void)
    func observeObject<T>(at objectRef: DatabaseReference, core: Core<T>, _ completion: @escaping (_ objectJSON: JSONObject?) -> Void)
    func retrieveObject<T, U: Unmarshaling>(at objectQuery: DatabaseQuery, core: Core<T>) -> U?

    func stopObservingObject<T>(at objectRef: DatabaseReference, core: Core<T>)
    func search<T>(with baseQuery: DatabaseQuery, key: String, value: String, core: Core<T>, completion: @escaping (_ json: JSONObject?) -> Void)
    
    func monitorConnection<T>(core: Core<T>)
    func stopMonitoringConnection<T>(core: Core<T>)
    func upload<T>(_ data: Data, contentType: String, to storageRef: StorageReference?, core: Core<T>, completion: @escaping (String?, URL?, Error?) -> Void)
    func upload<T>(from url: URL, to storageRef: StorageReference?, core: Core<T>, completion: @escaping (String?, URL?, Error?) -> Void)
    func delete<T>(at storageRef: StorageReference?, core: Core<T>, completion: @escaping (Error?) -> Void)

    // MARK: Overridable authentication functions

    func getUserId() -> String?
    func getUserEmailVerified() -> Bool
    func getUserToken(completion: @escaping (_ token: String?, _ error: Error?) -> Void)
    func sendEmailVerification<T>(to user: User?, app: FirebaseApp?, core: Core<T>)
    func reloadCurrentUser<T>(core: Core<T>)
    func logInUser<T>(with email: String, and password: String, core: Core<T>)
    func logInUser<T>(with token: String, core: Core<T>)
    func signUpUser<T>(with email: String, and password: String, core: Core<T>, completion: ((_ userId: String?) -> Void)?)
    func changeUserPassword<T>(to newPassword: String, core: Core<T>)
    func changeUserEmail<T>(to email: String, core: Core<T>)
    func resetPassword<T>(for email: String, app: FirebaseApp?, core: Core<T>)
    func logOutUser<T>(core: Core<T>)
}


// MARK: - Default implementation of protocol functions

public extension FirebaseReactorAccess {
    
    public func newObjectId() -> String {
        return ref.childByAutoId().key
    }
    
    public func createObject<T>(at ref: DatabaseReference, createNewChildId: Bool, removeId: Bool, parameters: JSONObject, core: Core<T>) {
        core.fire(command: CreateObject(at: ref, createNewChildId: createNewChildId, removeId: removeId, parameters: parameters))
    }
    
    public func updateObject<T>(at ref: DatabaseReference, parameters: JSONObject, core: Core<T>) {
        core.fire(command: UpdateObject(at: ref, parameters: parameters))
    }

    func updateObjectDirectly<T>(at ref: DatabaseReference, parameters: JSONObject, core: Core<T>) {
        core.fire(command: UpdateObjectDirectly(at: ref, parameters: parameters))
    }
    
    func removeObject<T>(at ref: DatabaseReference, core: Core<T>) {
        core.fire(command: RemoveObject(at: ref))
    }
    
    func getObject<T>(at objectRef: DatabaseQuery, core: Core<T>, completion: @escaping (_ objectJSON: JSONObject?) -> Void) {
        core.fire(command: GetObject(at: objectRef, completion: completion))
    }
    
    func observeObject<T>(at objectRef: DatabaseReference, core: Core<T>, _ completion: @escaping (_ objectJSON: JSONObject?) -> Void) {
        core.fire(command: ObserveObject(at: objectRef, completion: completion))
    }
    
    func retrieveObject<T, U: Unmarshaling>(at objectQuery: DatabaseQuery, core: Core<T>) -> U? {
        core.fire(command: RetrieveObject(at: objectQuery, objectType: U.self))
        return nil
    }

    func stopObservingObject<T>(at objectRef: DatabaseReference, core: Core<T>) {
        core.fire(command: StopObservingObject(at: objectRef))
    }
    
    func search<T>(with baseQuery: DatabaseQuery, key: String, value: String, core: Core<T>, completion: @escaping (_ json: JSONObject?) -> Void) {
        core.fire(command: Search(with: baseQuery, key: key, value: value, completion: completion))
    }
    
    func monitorConnection<T>(core: Core<T>) {
        core.fire(command: MonitorConnection(rootRef: ref))
    }
    
    func stopMonitoringConnection<T>(core: Core<T>) {
        core.fire(command: StopMonitorConnection(rootRef: ref))
    }
    
    func upload<T>(_ data: Data, contentType: String, to storageRef: StorageReference?, core: Core<T>, completion: @escaping (String?, URL?, Error?) -> Void) {
        guard let storageRef = storageRef else { completion(nil, nil, nil); return }
        core.fire(command: UploadData(data, contentType: contentType, to: storageRef, completion: completion))
    }
    
    func upload<T>(from url: URL, to storageRef: StorageReference?, core: Core<T>, completion: @escaping (String?, URL?, Error?) -> Void) {
        guard let storageRef = storageRef else { completion(nil, nil, nil); return }
     core.fire(command: UploadURL(url, to: storageRef, completion: completion))
    }
    
    func delete<T>(at storageRef: StorageReference?, core: Core<T>, completion: @escaping (Error?) -> Void) {
        guard let storageRef = storageRef else { completion(nil); return }
        core.fire(command: DeleteStorage(at: storageRef, completion: completion))
    }
    
}


// MARK: - Commands used in protocol functions

private struct CreateObject<T: State>: Command {
    
    var ref: DatabaseReference
    var createNewChildId: Bool
    var removeId: Bool
    var parameters: JSONObject
    
    init(at ref: DatabaseReference, createNewChildId: Bool, removeId: Bool, parameters: JSONObject) {
        self.ref = ref
        self.createNewChildId = createNewChildId
        self.removeId = removeId
        self.parameters = parameters
    }
    
    func execute(state: T, core: Core<T>) {
        let finalRef = createNewChildId ? ref.childByAutoId() : ref
        var parameters = self.parameters
        if removeId {
            parameters.removeValue(forKey: "id")
        }
        finalRef.setValue(parameters)
    }
    
}

private struct UpdateObject<T: State>: Command {
    
    var ref: DatabaseReference
    var parameters: JSONObject
    
    init(at ref: DatabaseReference, parameters: JSONObject) {
        self.ref = ref
        self.parameters = parameters
    }
    
    func execute(state: T, core: Core<T>) {
        recursivelyUpdate(ref, parameters: parameters)
    }
    
    func recursivelyUpdate(_ ref: DatabaseReference, parameters: JSONObject) {
        var result = JSONObject()
        for (key, value) in parameters {
            if let object = value as? JSONObject {
                recursivelyUpdate(ref.child(key), parameters: object)
            } else {
                result[key] = value
            }
        }
        ref.updateChildValues(result)
    }
    
}

private struct UpdateObjectDirectly<T: State>: Command {
    
    var ref: DatabaseReference
    var parameters: JSONObject
    
    init(at ref: DatabaseReference, parameters: JSONObject) {
        self.ref = ref
        self.parameters = parameters
    }
    
    func execute(state: T, core: Core<T>) {
        ref.updateChildValues(parameters)
    }
    
}

private struct RemoveObject<T: State>: Command {
    
    var ref: DatabaseReference
    
    init(at ref: DatabaseReference) {
        self.ref = ref
    }
    
    func execute(state: T, core: Core<T>) {
        ref.removeValue()
    }
    
}

private struct GetObject<T: State>: Command {
    
    var query: DatabaseQuery
    var completion: ((JSONObject?) -> Void)
    
    init(at query: DatabaseQuery, completion: @escaping ((JSONObject?) -> Void)) {
        self.query = query
        self.completion = completion
    }
    
    func execute(state: T, core: Core<T>) {
        query.observeSingleEvent(of: .value) { snapshot in
            self.completion(snapshot.jsonValue)
        }
    }
    
}

private struct ObserveObject<T: State>: Command {
    
    var ref: DatabaseReference
    var completion: ((JSONObject?) -> Void)
    
    init(at ref: DatabaseReference, completion: @escaping ((JSONObject?) -> Void)) {
        self.ref = ref
        self.completion = completion
    }
    
    func execute(state: T, core: Core<T>) {
        ref.observe(.value, with: { snapshot in
            self.completion(snapshot.jsonValue)
        })
        core.fire(event: ObjectObserved(path: self.ref.description(), observed: true))
    }
    
}

private struct StopObservingObject<T: State>: Command {
    
    var ref: DatabaseReference
    
    init(at ref: DatabaseReference) {
        self.ref = ref
    }
    
    func execute(state: T, core: Core<T>) {
        ref.removeAllObservers()
        core.fire(event: ObjectObserved(path: ref.description(), observed: false))
    }
    
}

private struct RetrieveObject<T: State, U: Unmarshaling>: Command {
    
    var query: DatabaseQuery
    
    init(at query: DatabaseQuery, objectType: U.Type) {
        self.query = query
    }
    
    func execute(state: T, core: Core<T>) {
        core.fire(command: GetObject(at: query) { json in
            guard let json = json else { return }
            do {
                let object = try U(object: json)
                core.fire(event: ObjectAdded(object: object))
            } catch {
                core.fire(event: ObjectErrored<U>(error: error))
            }
        })
    }
    
}

private struct Search<T: State>: Command {
    
    var baseQuery: DatabaseQuery
    var key: String
    var value: String
    var completion: ((JSONObject?) -> Void)
    
    init(with query: DatabaseQuery, key: String, value: String, completion: @escaping ((JSONObject?) -> Void)) {
        self.baseQuery = query
        self.key = key
        self.value = value
        self.completion = completion
    }
    
    func execute(state: T, core: Core<T>) {
        let query = baseQuery.queryOrdered(byChild: key).queryEqual(toValue: value)
        query.observeSingleEvent(of: .value, with: { snapshot in
            self.completion(snapshot.jsonValue)
        })
    }
    
}

private struct MonitorConnection<T: State>: Command {
    
    var rootRef: DatabaseReference
    
    init(rootRef: DatabaseReference) {
        self.rootRef = rootRef
    }
    
    func execute(state: T, core: Core<T>) {
        let connectedRef = self.rootRef.child(".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            guard let connected = snapshot.value as? Bool else { return }
            core.fire(event: FirebaseConnectionChanged(connected: connected))
        })
    }
    
}

private struct StopMonitorConnection<T: State>: Command {
    
    var rootRef: DatabaseReference
    
    init(rootRef: DatabaseReference) {
        self.rootRef = rootRef
    }
    
    func execute(state: T, core: Core<T>) {
        let connectedRef = self.rootRef.child(".info/connected")
        connectedRef.removeAllObservers()
    }
    
}

private struct UploadData<T: State>: Command {
    
    var data: Data
    var contentType: String
    var storageRef: StorageReference
    var completion: ((String?, URL?, Error?) -> Void)
    
    init(_ data: Data, contentType: String, to ref: StorageReference, completion: @escaping ((String?, URL?, Error?) -> Void)) {
        self.data = data
        self.contentType = contentType
        self.storageRef = ref
        self.completion = completion
    }
    
    func execute(state: T, core: Core<T>) {
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        storageRef.putData(data, metadata: metadata) { metadata, error in
            self.completion(metadata?.name, metadata?.downloadURL(), error)
        }
    }
    
}

private struct UploadURL<T: State>: Command {
    
    var url: URL
    var ref: StorageReference
    var completion: ((String?, URL?, Error?) -> Void)
    
    init(_ url: URL, to ref: StorageReference, completion: @escaping ((String?, URL?, Error?) -> Void)) {
        self.url = url
        self.ref = ref
        self.completion = completion
    }
    
    func execute(state: T, core: Core<T>) {
        ref.putFile(from: url, metadata: nil) { metadata, error in
            self.completion(metadata?.name, metadata?.downloadURL(), error)
        }
    }
    
}

private struct DeleteStorage<T: State>: Command {
    
    var storageRef: StorageReference
    var completion: ((Error?) -> Void)
    
    init(at ref: StorageReference, completion: @escaping ((Error?) -> Void)) {
        self.storageRef = ref
        self.completion = completion
    }
    
    func execute(state: T, core: Core<T>) {
        storageRef.delete { error in
            self.completion(error)
        }
    }
    
}

extension DataSnapshot {
    
    var jsonValue: JSONObject? {
        guard self.exists() && !(self.value is NSNull) else { return nil }
        if var json = self.value as? JSONObject {
            json["id"] = self.key
            return json
        } else if let value = self.value {
            return [self.key: value]
        } else {
            return nil
        }
    }
    
}


// MARK: - Default implementation of auth functions

public extension FirebaseReactorAccess {
    
    /// Attempts to retrieve the user's authentication id. If successful, it is returned.
    /// - returns: The user's authentication id, or nil if not authenticated
    func getUserId() -> String? {
        guard let currentApp = currentApp else { return nil}
        let auth = Auth.auth(app: currentApp)
        guard let user = auth.currentUser else { return nil }
        return user.uid
    }
    
    /// Attempts to retrieve user's email verified status.
    /// - returns: `true` if email has been verified, otherwise `false`.
    func getUserEmailVerified() -> Bool {
        guard let currentApp = currentApp else { return false }
        let auth = Auth.auth(app: currentApp)
        guard let user = auth.currentUser else { return false }
        return user.isEmailVerified
    }
    
    func getUserToken(completion: @escaping (_ token: String?, _ error: Error?) -> Void) {
        guard let currentApp = currentApp else { completion(nil, nil); return }
        let auth = Auth.auth(app: currentApp)
        guard let user = auth.currentUser else { completion(nil, nil); return }
        user.getIDToken(completion: completion)
    }

    func sendEmailVerification<T>(to user: User?, app: FirebaseApp?, core: Core<T>) {
        let app = app ?? currentApp
        core.fire(command: SendEmailVerification(for: user, app: app))
    }
    
    func reloadCurrentUser<T>(core: Core<T>) {
        core.fire(command: ReloadCurrentUser(app: currentApp))
    }
    
    func logInUser<T>(with email: String, and password: String, core: Core<T>) {
        core.fire(command: LogInUser(email: email, password: password, app: currentApp))
    }
    
    func logInUser<T>(with token: String, core: Core<T>) {
        core.fire(command: LogInWithCustomToken(token, app: currentApp))
    }
    
    func signUpUser<T>(with email: String, and password: String, core: Core<T>, completion: ((_ userId: String?) -> Void)?) {
        core.fire(command: SignUpUser(email: email, password: password, app: currentApp, completion: completion))
    }
    
    func changeUserPassword<T>(to newPassword: String, core: Core<T>) {
        core.fire(command: ChangeUserPassword(newPassword: newPassword, app: currentApp))
    }
    
    func changeUserEmail<T>(to email: String, core: Core<T>) {
        core.fire(command: ChangeUserEmail(email: email, app: currentApp))
    }
    
    func resetPassword<T>(for email: String, app: FirebaseApp?, core: Core<T>) {
        let app = app ?? currentApp
        core.fire(command: ResetPassword(email: email, app: app))
    }
    
    func logOutUser<T>(core: Core<T>) {
        core.fire(command: LogOutUser(app: currentApp))
    }
    
}


// MARK: - Commands used in authentication functions

/// Reloads the current user object. This is useful for checking whether `emailVerified` is now true.
/// - **app**: `FirebaseApp` - The current FirebaseApp
private struct ReloadCurrentUser<T: State>: Command {
    
    var app: FirebaseApp?
    
    func execute(state: T, core: Core<T>) {
        guard let app = app else { return }
        let auth = Auth.auth(app: app)
        guard let user = auth.currentUser else { return }
        user.reload { error in
            if let error = error {
                core.fire(event: UserAuthFailed(error: error))
            } else {
                core.fire(event: UserIdentified(userId: user.uid, emailVerified: user.isEmailVerified))
            }
        }
    }
    
}

/**
 Sends verification email to specified user, or current user if not specified.
 - **user**: `User` - User for which the email will be sent if not the current user
 - **app**: `FirebaseApp` - The current FirebaseApp
 */
private struct SendEmailVerification<T: State>: Command {
    
    var user: User?
    var app: FirebaseApp?
    
    init(for user: User? = nil, app: FirebaseApp? = FirebaseApp.app()) {
        self.user = user
        self.app = app
    }
    
    func execute(state: T, core: Core<T>) {
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
                core.fire(event: EmailVerificationError(error: error))
            } else {
                core.fire(event: UserAuthenticationEvent(action: .emailVerificationSent))
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
private struct LogInUser<T: State>: Command {
    
    var email: String
    var password: String
    var app: FirebaseApp?
    
    init(email: String, password: String, app: FirebaseApp?) {
        self.email = email
        self.password = password
        self.app = app
    }
    
    func execute(state: T, core: Core<T>) {
        guard let app = app else { return }
        let auth = Auth.auth(app: app)
        auth.signIn(withEmail: email, password: password) { user, error in
            if let error = error {
                core.fire(event: UserAuthFailed(error: error))
            } else if let user = user {
                core.fire(event: UserLoggedIn(userId: user.uid, emailVerified: user.isEmailVerified, email: user.email))
            } else {
                core.fire(event: UserAuthFailed(error: FirebaseAuthenticationError.logInMissingUserId))
            }
        }
    }
    
}

/**
 Authenticates the user with the custom token. If successful, fires and event with
 the user‘s id (`UserLoggedIn`), otherwise fires a failed event with an error
 (`UserAuthFailed`).
 
 - **token**:   The custom token
 */
private struct LogInWithCustomToken<T: State>: Command {
    
    var token: String
    var app: FirebaseApp?
    
    init(_ token: String, app: FirebaseApp?) {
        self.token = token
        self.app = app
    }
    
    func execute(state: T, core: Core<T>) {
        guard let app = app else { return }
        let auth = Auth.auth(app: app)
        auth.signIn(withCustomToken: token) { user, error in
            if let error = error {
                core.fire(event: UserAuthFailed(error: error))
            } else if let user = user {
                core.fire(event: UserLoggedIn(userId: user.uid, emailVerified: user.isEmailVerified, email: user.email))
            } else {
                core.fire(event: UserAuthFailed(error: FirebaseAuthenticationError.logInMissingUserId))
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
private struct SignUpUser<T: State>: Command {
    
    var email: String
    var password: String
    var app: FirebaseApp?
    var completion: ((String?) -> Void)?
    
    init(email: String, password: String, app: FirebaseApp?, completion: ((String?) -> Void)?) {
        self.email = email
        self.password = password
        self.app = app
        self.completion = completion
    }
    
    func execute(state: T, core: Core<T>) {
        guard let app = app else { return }
        let auth = Auth.auth(app: app)
        auth.createUser(withEmail: email, password: password) { user, error in
            if let error = error {
                core.fire(event: UserAuthFailed(error: error))
                self.completion?(nil)
            } else if let user = user {
                core.fire(event: UserSignedUp(userId: user.uid, email: self.email))
                if let completion = self.completion {
                    completion(user.uid)
                } else {
                    core.fire(event: UserLoggedIn(userId: user.uid, email: self.email))
                }
            } else {
                core.fire(event: UserAuthFailed(error: FirebaseAuthenticationError.signUpFailedLogIn))
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
private struct ChangeUserPassword<T: State>: Command {
    
    var newPassword: String
    var app: FirebaseApp?
    
    init(newPassword: String, app: FirebaseApp?) {
        self.newPassword = newPassword
        self.app = app
    }
    
    func execute(state: T, core: Core<T>) {
        guard let app = app else { return }
        let auth = Auth.auth(app: app)
        guard let user = auth.currentUser else {
            core.fire(event: UserAuthFailed(error: FirebaseAuthenticationError.currentUserNotFound))
            return
        }
        user.updatePassword(to: newPassword) { error in
            if let error = error {
                core.fire(event: UserAuthFailed(error: error))
            } else {
                core.fire(event: UserAuthenticationEvent(action: FirebaseAuthenticationAction.passwordChanged))
            }
        }
    }
    
}

/**
 Change a user’s email address.
 
 - **email**: `String` - The new email address for the user
 - **app**: `FirebaseApp` - The current FirebaseApp
 */
private struct ChangeUserEmail<T: State>: Command {
    
    var email: String
    var app: FirebaseApp?
    
    init(email: String, app: FirebaseApp?) {
        self.email = email
        self.app = app
    }
    
    func execute(state: T, core: Core<T>) {
        guard let app = app else { return }
        let auth = Auth.auth(app: app)
        guard let user = auth.currentUser else {
            core.fire(event: UserAuthFailed(error: FirebaseAuthenticationError.currentUserNotFound))
            return
        }
        user.updateEmail(to: email) { error in
            if let error = error {
                core.fire(event: UserAuthFailed(error: error))
            } else {
                core.fire(event: UserAuthenticationEvent(action: FirebaseAuthenticationAction.emailChanged))
            }
        }
    }
    
}
/**
 Send the user a reset password email.
 - **email**: The user’s email address
 - **app**: `FirebaseApp` - The current FirebaseApp
 */
private struct ResetPassword<T: State>: Command {
    
    var email: String
    var app: FirebaseApp?
    
    init(email: String, app: FirebaseApp? = FirebaseApp.app()) {
        self.email = email
        self.app = app
    }
    
    func execute(state: T, core: Core<T>) {
        guard let app = app else { return }
        let auth = Auth.auth(app: app)
        auth.sendPasswordReset(withEmail: email) { error in
            if let error = error {
                core.fire(event: UserAuthFailed(error: error))
            } else {
                core.fire(event: UserAuthenticationEvent(action: FirebaseAuthenticationAction.passwordReset))
            }
        }
    }
    
}

/// Unauthenticates the current user and fires a `UserLoggedOut` event.
/// - **app**: `FirebaseApp` - The current FirebaseApp
private struct LogOutUser<T: State>: Command {
    
    var app: FirebaseApp?
    
    init(app: FirebaseApp? = FirebaseApp.app()) {
        self.app = app
    }
    
    func execute(state: T, core: Core<T>) {
        do {
            guard let app = app else { return }
            let auth = Auth.auth(app: app)
            try auth.signOut()
            core.fire(event: UserLoggedOut())
        } catch {
            core.fire(event: UserAuthFailed(error: error))
        }
    }
    
}
