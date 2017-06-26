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
    func createObject<T: State>(at ref: DatabaseReference, createNewChildId: Bool, removeId: Bool, parameters: JSONObject, core: Core<T>)
    
    func updateObject<T: State>(at ref: DatabaseReference, parameters: JSONObject, core: Core<T>)
    func updateObjectDirectly<T: State>(at ref: DatabaseReference, parameters: JSONObject, core: Core<T>)
    func removeObject<T: State>(at ref: DatabaseReference, core: Core<T>)
    func getObject<T: State>(at objectRef: DatabaseReference, core: Core<T>, completion: @escaping (_ objectJSON: JSONObject?) -> Void)
    func observeObject<T: State>(at objectRef: DatabaseReference, core: Core<T>, _ completion: @escaping (_ objectJSON: JSONObject?) -> Void)
    
    func stopObservingObject<T: State>(at objectRef: DatabaseReference, core: Core<T>)
    func search<T: State>(with baseQuery: DatabaseQuery, key: String, value: String, core: Core<T>, completion: @escaping (_ json: JSONObject?) -> Void)
    
    func monitorConnection<T: State>(core: Core<T>)
    func stopMonitoringConnection<T: State>(core: Core<T>)
    func upload<T: State>(_ data: Data, contentType: String, to storageRef: StorageReference, core: Core<T>, completion: @escaping (String?, URL?, Error?) -> Void)
    func upload<T: State>(from url: URL, to storageRef: StorageReference, core: Core<T>, completion: @escaping (String?, URL?, Error?) -> Void)
    func delete<T: State>(at storageRef: StorageReference, core: Core<T>, completion: @escaping (Error?) -> Void)

    // MARK: - Overridable authentication functions

    func getUserId() -> String?
    func getUserEmailVerified() -> Bool
    func sendEmailVerification<T: State>(to user: User?, core: Core<T>)
    func reloadCurrentUser<T: State>(core: Core<T>)
    func logInUser<T: State>(with email: String, and password: String, core: Core<T>)
    func signUpUser<T: State>(with email: String, and password: String, core: Core<T>, completion: ((_ userId: String?) -> Void)?)
    func changeUserPassword<T: State>(to newPassword: String, core: Core<T>)
    func changeUserEmail<T: State>(to email: String, core: Core<T>)
    func resetPassword<T: State>(for email: String, core: Core<T>)
    func logOutUser<T: State>(core: Core<T>)
}


public extension FirebaseReactorAccess {
    
    public func newObjectId() -> String {
        return ref.childByAutoId().key
    }
    
    public func createObject<T: State>(at ref: DatabaseReference, createNewChildId: Bool, removeId: Bool, parameters: JSONObject, core: Core<T>) {
        core.fire(command: CreateObject(at: ref, createNewChildId: createNewChildId, removeId: removeId, parameters: parameters))
    }
    
    public func updateObject<T: State>(at ref: DatabaseReference, parameters: JSONObject, core: Core<T>) {
        core.fire(command: UpdateObject(at: ref, parameters: parameters))
    }

    func updateObjectDirectly<T: State>(at ref: DatabaseReference, parameters: JSONObject, core: Core<T>) {
        core.fire(command: UpdateObjectDirectly(at: ref, parameters: parameters))
    }
    
    func removeObject<T: State>(at ref: DatabaseReference, core: Core<T>) {
        core.fire(command: RemoveObject(at: ref))
    }
    
    func getObject<T: State>(at objectRef: DatabaseReference, core: Core<T>, completion: @escaping (_ objectJSON: JSONObject?) -> Void) {
        core.fire(command: GetObject(at: objectRef, completion: completion))
    }
    
    func observeObject<T: State>(at objectRef: DatabaseReference, core: Core<T>, _ completion: @escaping (_ objectJSON: JSONObject?) -> Void) {
        core.fire(command: ObserveObject(at: objectRef, completion: completion))
    }
    
    func stopObservingObject<T: State>(at objectRef: DatabaseReference, core: Core<T>) {
        core.fire(command: StopObservingObject(at: objectRef))
    }
    
    func search<T: State>(with baseQuery: DatabaseQuery, key: String, value: String, core: Core<T>, completion: @escaping (_ json: JSONObject?) -> Void) {
        core.fire(command: Search(with: baseQuery, key: key, value: value, completion: completion))
    }
    
    func monitorConnection<T: State>(core: Core<T>) {
        core.fire(command: MonitorConnection(rootRef: ref))
    }
    
    func stopMonitoringConnection<T: State>(core: Core<T>) {
        core.fire(command: StopMonitorConnection(rootRef: ref))
    }
    
    func upload<T: State>(_ data: Data, contentType: String, to storageRef: StorageReference, core: Core<T>, completion: @escaping (String?, URL?, Error?) -> Void) {
        core.fire(command: UploadData(data, contentType: contentType, to: storageRef, completion: completion))
    }
    
    func upload<T: State>(from url: URL, to storageRef: StorageReference, core: Core<T>, completion: @escaping (String?, URL?, Error?) -> Void) {
     core.fire(command: UploadURL(url, to: storageRef, completion: completion))
    }
    
    func delete<T: State>(at storageRef: StorageReference, core: Core<T>, completion: @escaping (Error?) -> Void) {
        core.fire(command: DeleteStorage(at: storageRef, completion: completion))
    }
    
    // AUTH
    func sendEmailVerification<T: State>(to user: User?, core: Core<T>) {
        core.fire(command: SendEmailVerification(user: user, app: currentApp))
    }
    
    func reloadCurrentUser<T: State>(core: Core<T>) {
        core.fire(command: ReloadCurrentUser(app: currentApp))
    }
    
    func logInUser<T: State>(with email: String, and password: String, core: Core<T>) {
        core.fire(command: LogInUser(email: email, password: password, app: currentApp))
    }
    
    func signUpUser<T: State>(with email: String, and password: String, core: Core<T>, completion: ((_ userId: String?) -> Void)?) {
        core.fire(command: SignUpUser(email: email, password: password, app: currentApp, completion: completion))
    }
    
    func changeUserPassword<T: State>(to newPassword: String, core: Core<T>) {
        core.fire(command: ChangeUserPassword(newPassword: newPassword, app: currentApp))
    }
    
    func changeUserEmail<T: State>(to email: String, core: Core<T>) {
        core.fire(command: ChangeUserEmail(email: email, app: currentApp))
    }
    
    func resetPassword<T: State>(for email: String, core: Core<T>) {
        core.fire(command: ResetPassword(email: email, app: currentApp))
    }
    
    func logOutUser<T: State>(core: Core<T>) {
        core.fire(command: LogOutUser(app: currentApp))
    }

}


public struct CreateObject<T: State>: Command {
    
    public var ref: DatabaseReference
    public var createNewChildId: Bool
    public var removeId: Bool
    public var parameters: JSONObject
    
    public init(at ref: DatabaseReference, createNewChildId: Bool, removeId: Bool, parameters: JSONObject) {
        self.ref = ref
        self.createNewChildId = createNewChildId
        self.removeId = removeId
        self.parameters = parameters
    }
    
    public func execute(state: T, core: Core<T>) {
        let finalRef = createNewChildId ? ref.childByAutoId() : ref
        var parameters = self.parameters
        if removeId {
            parameters.removeValue(forKey: "id")
        }
        finalRef.setValue(parameters)
    }
    
}

public struct UpdateObject<T: State>: Command {
    
    public var ref: DatabaseReference
    public var parameters: JSONObject
    
    public init(at ref: DatabaseReference, parameters: JSONObject) {
        self.ref = ref
        self.parameters = parameters
    }
    
    public func execute(state: T, core: Core<T>) {
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

public struct UpdateObjectDirectly<T: State>: Command {
    
    public var ref: DatabaseReference
    public var parameters: JSONObject
    
    public init(at ref: DatabaseReference, parameters: JSONObject) {
        self.ref = ref
        self.parameters = parameters
    }
    
    public func execute(state: T, core: Core<T>) {
        ref.updateChildValues(parameters)
    }
    
}

public struct RemoveObject<T: State>: Command {
    
    public var ref: DatabaseReference
    
    public init(at ref: DatabaseReference) {
        self.ref = ref
    }
    
    public func execute(state: T, core: Core<T>) {
        ref.removeValue()
    }
    
}

public struct GetObject<T: State>: Command {
    
    public var ref: DatabaseReference
    public var completion: ((JSONObject?) -> Void)
    
    public init(at ref: DatabaseReference, completion: @escaping ((JSONObject?) -> Void)) {
        self.ref = ref
        self.completion = completion
    }
    
    public func execute(state: T, core: Core<T>) {
        ref.observeSingleEvent(of: .value) { snapshot in
            self.completion(snapshot.jsonValue)
        }
    }
    
}

public struct ObserveObject<T: State>: Command {
    
    public var ref: DatabaseReference
    public var completion: ((JSONObject?) -> Void)
    
    public init(at ref: DatabaseReference, completion: @escaping ((JSONObject?) -> Void)) {
        self.ref = ref
        self.completion = completion
    }
    
    public func execute(state: T, core: Core<T>) {
        ref.observe(.value, with: { snapshot in
            self.completion(snapshot.jsonValue)
            core.fire(event: ReactorObjectObserved(path: self.ref.description(), observed: true))
        })
    }
    
}

public struct StopObservingObject<T: State>: Command {
    
    public var ref: DatabaseReference
    
    public init(at ref: DatabaseReference) {
        self.ref = ref
    }
    
    public func execute(state: T, core: Core<T>) {
        ref.removeAllObservers()
        core.fire(event: ReactorObjectObserved(path: ref.description(), observed: false))
    }
    
}

public struct Search<T: State>: Command {
    
    public var baseQuery: DatabaseQuery
    public var key: String
    public var value: String
    public var completion: ((JSONObject?) -> Void)
    
    public init(with query: DatabaseQuery, key: String, value: String, completion: @escaping ((JSONObject?) -> Void)) {
        self.baseQuery = query
        self.key = key
        self.value = value
        self.completion = completion
    }
    
    public func execute(state: T, core: Core<T>) {
        let query = baseQuery.queryOrdered(byChild: key).queryEqual(toValue: value)
        query.observeSingleEvent(of: .value, with: { snapshot in
            self.completion(snapshot.jsonValue)
        })
    }
    
}

public struct MonitorConnection<T: State>: Command {
    
    public var rootRef: DatabaseReference
    
    public init(rootRef: DatabaseReference) {
        self.rootRef = rootRef
    }
    
    public func execute(state: T, core: Core<T>) {
        let connectedRef = self.rootRef.child(".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            guard let connected = snapshot.value as? Bool else { return }
            core.fire(event: ReactorFirebaseConnectionChanged(connected: connected))
        })
    }
    
}

public struct StopMonitorConnection<T: State>: Command {
    
    public var rootRef: DatabaseReference
    
    public init(rootRef: DatabaseReference) {
        self.rootRef = rootRef
    }
    
    public func execute(state: T, core: Core<T>) {
        let connectedRef = self.rootRef.child(".info/connected")
        connectedRef.removeAllObservers()
    }
    
}

public struct UploadData<T: State>: Command {
    
    public var data: Data
    public var contentType: String
    public var storageRef: StorageReference
    public var completion: ((String?, URL?, Error?) -> Void)
    
    
    public init(_ data: Data, contentType: String, to ref: StorageReference, completion: @escaping ((String?, URL?, Error?) -> Void)) {
        self.data = data
        self.contentType = contentType
        self.storageRef = ref
        self.completion = completion
    }
    
    public func execute(state: T, core: Core<T>) {
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        storageRef.putData(data, metadata: metadata) { metadata, error in
            self.completion(metadata?.name, metadata?.downloadURL(), error)
        }
    }
    
}

public struct UploadURL<T: State>: Command {
    
    public var url: URL
    public var ref: StorageReference
    public var completion: ((String?, URL?, Error?) -> Void)
    
    public init(_ url: URL, to ref: StorageReference, completion: @escaping ((String?, URL?, Error?) -> Void)) {
        self.url = url
        self.ref = ref
        self.completion = completion
    }
    
    public func execute(state: T, core: Core<T>) {
        ref.putFile(from: url, metadata: nil) { metadata, error in
            self.completion(metadata?.name, metadata?.downloadURL(), error)
        }
    }
    
}

public struct DeleteStorage<T: State>: Command {
    
    public var storageRef: StorageReference
    public var completion: ((Error?) -> Void)
    
    public init(at ref: StorageReference, completion: @escaping ((Error?) -> Void)) {
        self.storageRef = ref
        self.completion = completion
    }
    
    public func execute(state: T, core: Core<T>) {
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
