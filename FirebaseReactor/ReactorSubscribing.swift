/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
 |  ‾        ‾        ‾
 */

import Foundation
import Firebase
import Marshal
import Reactor

/// A protocol to be adopted by sub states that hold a flag indicating whether an object
/// has been subscribed to in Firebase or not.
public protocol SubscribingState: State {
    var isSubscribed: Bool { get }
    associatedtype SubscribingObject: Unmarshaling, EndpointNaming
}

/// Protocol for objects which have an associated endpoint name
public protocol EndpointNaming {
    static var endpointName: String { get }
}


/**
 An error that occurred parsing data from a Firebase event.
 
 - `NoData`:    The snapshot for the event contained no data
 - `MalformedData`:  The data in the snapshot could not be parsed as JSON
 */

public enum FirebaseSubscriptionError: Error {
    case noData(path: String)
    case malformedData(path: String)
}

extension FirebaseSubscriptionError: Equatable { }

public func ==(lhs: FirebaseSubscriptionError, rhs: FirebaseSubscriptionError) -> Bool {
    switch (lhs, rhs) {
    case (.noData(_), .noData(_)):
        return true
    case (.malformedData(_), .malformedData(_)):
        return true
    default:
        return false
    }
}

/**
 This protocol is adopted by a state object in order to receive updates of a specific
 data object from Firebase.
 
 - Note: The object must also adopt `Unmarshaling` in order to parse JSON into an object
 of that type.
 */

public extension SubscribingState {
    
    typealias ObjectType = Self.SubscribingObject
    
    /**
     Calling this function results in the dispatching events to the core for the following
     events that occur in Firebase matching the given query. The actions are generic actions
     scoped to the data object on which the function is called.
     
     - Note: The `ObjectErrored` event can be called on any of those events if the resulting
     data does not exist, or cannot be parsed from JSON into the data object. It is likewise a
     generic event scoped to the data object.
     
     - `ChildAdded` event:      `ObjectAdded` event
     - `ChildChanged` event:    `ObjectChanged` event
     - `ChildRemoved` event:    `ObjectRemoved` event
     
     - Parameters:
     - query: The Firebase database query to which to subscribe. This is usually
     constructed from the base `ref` using `childByAppendingPath(_)` or other
     `FQuery` functions.
     */
    public func subscribeToObjects<T>(_ query: DatabaseQuery, core: Core<T>) {
        if !self.isSubscribed {
            let idKey = "id"
            let refKey = "ref"
            
            // Additions
            query.observe(.childAdded, with: { snapshot in
                guard snapshot.exists() && !(snapshot.value is NSNull) else {
                    core.fire(event: ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.noData(path: query.ref.description())))
                    return
                }
                guard var json = snapshot.value as? JSONObject else {
                    core.fire(event: ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.malformedData(path: query.ref.description())))
                    return
                }
                json[idKey] = snapshot.key
                json[refKey] = snapshot.ref.description()
                do {
                    let object = try ObjectType(object: json)
                    core.fire(event: ObjectAdded(object: object))
                } catch {
                    core.fire(event: ObjectErrored<ObjectType>(error: error))
                }
            })
            
            // Changes
            query.observe(.childChanged, with: { snapshot in
                guard snapshot.exists() && !(snapshot.value is NSNull) else {
                    core.fire(event: ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.noData(path: query.ref.description())))
                    return
                }
                guard var json = snapshot.value as? JSONObject else {
                    core.fire(event: ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.malformedData(path: query.ref.description())))
                    return
                }
                json[idKey] = snapshot.key
                json[refKey] = snapshot.ref.description()
                do {
                    let object = try ObjectType(object: json)
                    core.fire(event: ObjectChanged(object: object))
                } catch {
                    core.fire(event: ObjectErrored<ObjectType>(error: error))
                }
            })
            
            // Removals
            query.observe(.childRemoved, with: { snapshot in
                guard snapshot.exists() && !(snapshot.value is NSNull) else {
                    core.fire(event: ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.noData(path: query.ref.description())))
                    return
                }
                guard var json = snapshot.value as? JSONObject else {
                    core.fire(event: ObjectErrored<ObjectType>(error: FirebaseSubscriptionError.malformedData(path: query.ref.description())))
                    return
                }
                json[idKey] = snapshot.key
                json[refKey] = snapshot.ref.description()
                do {
                    let object = try ObjectType(object: json)
                    core.fire(event: ObjectRemoved(object: object))
                } catch {
                    core.fire(event: ObjectErrored<ObjectType>(error: error))
                }
            })
            core.fire(event: ObjectSubscribed(subscribed: true, state: self))
        }
    }
    
    /**
     Removes all observers on a `FIRDatabaseQuery`.
     
     - Note: This is often used when signing out, or switching Firebase apps.
     
     - Parameter query: The query that was originally used to subscribe to events.
     */
    public func removeSubscriptions<T>(_ query: DatabaseQuery, core: Core<T>) {
        if self.isSubscribed {
            query.removeAllObservers()
            core.fire(event: ObjectSubscribed(subscribed: false, state: self))
        }
    }
    
}
