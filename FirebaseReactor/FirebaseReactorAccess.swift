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
    func observeObject<T: State>(at objectRef: DatabaseReference, core: Core<T>, _ callback: @escaping (_ objectJSON: JSONObject?) -> Void)
    
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
        core.fire(command: CreateObject(ref: ref, createNewChildId: createNewChildId, removeId: removeId, parameters: parameters))
    }
    
    public func updateObject<T: State>(at ref: DatabaseReference, parameters: JSONObject, core: Core<T>) {
        core.fire(command: UpdateObject(ref: ref, parameters: parameters))
    }

    
    
    
}


public struct CreateObject<T: State>: Command {
    
    public var ref: DatabaseReference
    public var createNewChildId: Bool
    public var removeId: Bool
    public var parameters: JSONObject
    
    public init(ref: DatabaseReference, createNewChildId: Bool, removeId: Bool, parameters: JSONObject) {
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
    
    public init(ref: DatabaseReference, parameters: JSONObject) {
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
