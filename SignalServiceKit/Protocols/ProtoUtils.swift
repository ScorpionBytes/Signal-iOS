//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation
import LibSignalClient

// TODO: Convert to enum once no objc depends on this.
@objc
internal class ProtoUtils: NSObject {

    @objc
    internal static func addLocalProfileKeyIfNecessary(_ thread: TSThread, dataMessageBuilder: SSKProtoDataMessageBuilder, transaction: SDSAnyReadTransaction) {
        if shouldMessageHaveLocalProfileKey(thread, transaction: transaction) {
            dataMessageBuilder.setProfileKey(localProfileKey(tx: transaction).serialize().asData)
        }
    }

    @objc
    internal static func addLocalProfileKeyIfNecessary(forThread thread: TSThread, profileKeySnapshot: Data?, dataMessageBuilder: SSKProtoDataMessageBuilder, transaction: SDSAnyReadTransaction) {
        let profileKey = localProfileKey(tx: transaction)
        let canAddLocalProfileKey: Bool = (
            profileKeySnapshot?.ows_constantTimeIsEqual(to: profileKey.serialize().asData) == true
            || shouldMessageHaveLocalProfileKey(thread, transaction: transaction)
        )
        if canAddLocalProfileKey {
            dataMessageBuilder.setProfileKey(profileKey.serialize().asData)
        }
    }

    @objc
    internal static func addLocalProfileKeyIfNecessary(_ thread: TSThread, callMessageBuilder: SSKProtoCallMessageBuilder, transaction: SDSAnyReadTransaction) {
        if shouldMessageHaveLocalProfileKey(thread, transaction: transaction) {
            callMessageBuilder.setProfileKey(localProfileKey(tx: transaction).serialize().asData)
        }
    }

    static func localProfileKey(tx: SDSAnyReadTransaction) -> ProfileKey {
        let profileManager = SSKEnvironment.shared.profileManagerRef
        // Force unwrap is from the original ObjC implementation. It is "safe"
        // because we generate missing profile keys in warmCaches.
        return profileManager.localProfileKey(tx: tx)!
    }

    private static func shouldMessageHaveLocalProfileKey(_ thread: TSThread, transaction: SDSAnyReadTransaction) -> Bool {
        // Group threads will return YES if the group is in the whitelist
        // Contact threads will return YES if the contact is in the whitelist.
        SSKEnvironment.shared.profileManagerRef.isThread(inProfileWhitelist: thread, transaction: transaction)
    }
}
