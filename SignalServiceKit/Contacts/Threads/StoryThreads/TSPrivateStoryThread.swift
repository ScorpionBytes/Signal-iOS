//
// Copyright 2022 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

public extension TSPrivateStoryThread {
    @objc
    class var myStoryUniqueId: String {
        // My Story always uses a UUID of all 0s
        "00000000-0000-0000-0000-000000000000"
    }

    class func getMyStory(transaction: SDSAnyReadTransaction) -> TSPrivateStoryThread! {
        anyFetchPrivateStoryThread(uniqueId: myStoryUniqueId, transaction: transaction)
    }

    @discardableResult
    class func getOrCreateMyStory(transaction: SDSAnyWriteTransaction) -> TSPrivateStoryThread! {
        if let myStory = getMyStory(transaction: transaction) { return myStory }

        let myStory = TSPrivateStoryThread(uniqueId: myStoryUniqueId, name: "", allowsReplies: true, addresses: [], viewMode: .blockList)
        myStory.anyInsert(transaction: transaction)
        return myStory
    }

    // MARK: -

    @objc
    var distributionListIdentifier: Data? { UUID(uuidString: uniqueId)?.data }

    override func recipientAddresses(with transaction: SDSAnyReadTransaction) -> [SignalServiceAddress] {
        switch storyViewMode {
        case .default:
            owsFailDebug("Unexpectedly have private story with no view mode")
            return []
        case .explicit, .disabled:
            return addresses
        case .blockList:
            return profileManager.allWhitelistedRegisteredAddresses(tx: transaction).filter { !addresses.contains($0) && !$0.isLocalAddress }
        }
    }

    // MARK: -

    override func updateWithShouldThreadBeVisible(_ shouldThreadBeVisible: Bool, transaction: SDSAnyWriteTransaction) {
        super.updateWithShouldThreadBeVisible(shouldThreadBeVisible, transaction: transaction)
        updateWithStoryViewMode(.disabled, transaction: transaction)
    }

    /// Update this private story thread with the given view mode and
    /// corresponding addresses.
    ///
    /// - Parameter updateStorageService
    /// Whether or not we should update the distribution list this thread
    /// represents in Storage Service.
    /// - Parameter updateHasSetMyStoryPrivacyIfNeeded
    /// Whether or not we should set the local "has set My Story privacy" flag
    /// (to `true`), assuming this thread represents "My Story". Only callers
    /// who will be managing that flag's state themselves – at the time of
    /// writing, that is exclusively Backups – should set this to `false`.
    func updateWithStoryViewMode(
        _ storyViewMode: TSThreadStoryViewMode,
        addresses: [SignalServiceAddress],
        updateStorageService: Bool,
        updateHasSetMyStoryPrivacyIfNeeded: Bool = true,
        transaction tx: SDSAnyWriteTransaction
    ) {
        if updateHasSetMyStoryPrivacyIfNeeded, isMyStory {
            StoryManager.setHasSetMyStoriesPrivacy(
                true,
                shouldUpdateStorageService: updateStorageService,
                transaction: tx
            )
        }

        anyUpdatePrivateStoryThread(transaction: tx) { privateStoryThread in
            privateStoryThread.storyViewMode = storyViewMode
            privateStoryThread.addresses = addresses
        }

        if updateStorageService, let distributionListIdentifier {
            storageServiceManager.recordPendingUpdates(
                updatedStoryDistributionListIds: [ distributionListIdentifier ]
            )
        }
    }
}
