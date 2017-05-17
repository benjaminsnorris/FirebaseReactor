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

public protocol FirebaseAccess {
    
    /// The base ref for your Firebase app
    var ref: DatabaseReference { get }
    var currentApp: FirebaseApp? { get }
    
}
