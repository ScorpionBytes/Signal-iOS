//
//  Copyright (c) 2022 Open Whisper Systems. All rights reserved.
//

#import "TSInvalidIdentityKeyReceivingErrorMessage.h"
#import "AxolotlExceptions.h"
#import "NSData+keyVersionByte.h"
#import "OWSFingerprint.h"
#import "OWSIdentityManager.h"
#import "OWSMessageManager.h"
#import "SSKEnvironment.h"
#import "TSContactThread.h"
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((deprecated)) @interface TSInvalidIdentityKeyReceivingErrorMessage()

@property (nonatomic, readonly, copy) NSString *authorId;

@property (atomic, nullable) NSData *envelopeData;

@end

#pragma mark -

@interface TSInvalidIdentityKeyReceivingErrorMessage (ImplementedInSwift)
- (nullable NSData *)identityKeyFromEncodedPreKeySignalMessage:(NSData *)pksmBytes error:(NSError **)error;
@end

@implementation TSInvalidIdentityKeyReceivingErrorMessage {
    // Not using a property declaration in order to exclude from DB serialization
    SSKProtoEnvelope *_Nullable _envelope;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    return [super initWithCoder:coder];
}

#ifdef TESTABLE_BUILD
// We no longer create these messages, but they might exist on legacy clients so it's useful to be able to
// create them with the debug UI
+ (nullable instancetype)untrustedKeyWithEnvelope:(SSKProtoEnvelope *)envelope
                                  withTransaction:(SDSAnyWriteTransaction *)transaction
{
    TSContactThread *contactThread = [TSContactThread getOrCreateThreadWithContactAddress:envelope.sourceAddress
                                                                              transaction:transaction];

    // Legit usage of senderTimestamp, references message which failed to decrypt
    TSInvalidIdentityKeyReceivingErrorMessage *errorMessage =
        [[self alloc] initForUnknownIdentityKeyWithTimestamp:envelope.timestamp
                                                      thread:contactThread
                                            incomingEnvelope:envelope];
    return errorMessage;
}
#endif

- (nullable instancetype)initForUnknownIdentityKeyWithTimestamp:(uint64_t)timestamp
                                                         thread:(TSThread *)thread
                                               incomingEnvelope:(SSKProtoEnvelope *)envelope
{
    TSErrorMessageBuilder *builder =
        [TSErrorMessageBuilder errorMessageBuilderWithThread:thread errorType:TSErrorMessageWrongTrustedIdentityKey];
    builder.timestamp = timestamp;
    self = [super initErrorMessageWithBuilder:builder];
    if (!self) {
        return self;
    }
    
    NSError *error;
    _envelopeData = [envelope serializedDataAndReturnError:&error];
    if (!_envelopeData || error != nil) {
        OWSFailDebug(@"failure: envelope data failed with error: %@", error);
        return nil;
    }

    _authorId = envelope.sourceE164;

    return self;
}

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithGrdbId:(int64_t)grdbId
                      uniqueId:(NSString *)uniqueId
             receivedAtTimestamp:(uint64_t)receivedAtTimestamp
                          sortId:(uint64_t)sortId
                       timestamp:(uint64_t)timestamp
                  uniqueThreadId:(NSString *)uniqueThreadId
                   attachmentIds:(NSArray<NSString *> *)attachmentIds
                            body:(nullable NSString *)body
                      bodyRanges:(nullable MessageBodyRanges *)bodyRanges
                    contactShare:(nullable OWSContact *)contactShare
                 expireStartedAt:(uint64_t)expireStartedAt
                       expiresAt:(uint64_t)expiresAt
                expiresInSeconds:(unsigned int)expiresInSeconds
               isGroupStoryReply:(BOOL)isGroupStoryReply
              isViewOnceComplete:(BOOL)isViewOnceComplete
               isViewOnceMessage:(BOOL)isViewOnceMessage
                     linkPreview:(nullable OWSLinkPreview *)linkPreview
                  messageSticker:(nullable MessageSticker *)messageSticker
                   quotedMessage:(nullable TSQuotedMessage *)quotedMessage
    storedShouldStartExpireTimer:(BOOL)storedShouldStartExpireTimer
           storyAuthorUuidString:(nullable NSString *)storyAuthorUuidString
                  storyTimestamp:(nullable NSNumber *)storyTimestamp
              wasRemotelyDeleted:(BOOL)wasRemotelyDeleted
                       errorType:(TSErrorMessageType)errorType
                            read:(BOOL)read
                recipientAddress:(nullable SignalServiceAddress *)recipientAddress
                          sender:(nullable SignalServiceAddress *)sender
             wasIdentityVerified:(BOOL)wasIdentityVerified
                        authorId:(NSString *)authorId
                    envelopeData:(nullable NSData *)envelopeData
{
    self = [super initWithGrdbId:grdbId
                        uniqueId:uniqueId
               receivedAtTimestamp:receivedAtTimestamp
                            sortId:sortId
                         timestamp:timestamp
                    uniqueThreadId:uniqueThreadId
                     attachmentIds:attachmentIds
                              body:body
                        bodyRanges:bodyRanges
                      contactShare:contactShare
                   expireStartedAt:expireStartedAt
                         expiresAt:expiresAt
                  expiresInSeconds:expiresInSeconds
                 isGroupStoryReply:isGroupStoryReply
                isViewOnceComplete:isViewOnceComplete
                 isViewOnceMessage:isViewOnceMessage
                       linkPreview:linkPreview
                    messageSticker:messageSticker
                     quotedMessage:quotedMessage
      storedShouldStartExpireTimer:storedShouldStartExpireTimer
             storyAuthorUuidString:storyAuthorUuidString
                    storyTimestamp:storyTimestamp
                wasRemotelyDeleted:wasRemotelyDeleted
                         errorType:errorType
                              read:read
                  recipientAddress:recipientAddress
                            sender:sender
               wasIdentityVerified:wasIdentityVerified];

    if (!self) {
        return self;
    }

    _authorId = authorId;
    _envelopeData = envelopeData;

    return self;
}

// clang-format on

// --- CODE GENERATION MARKER

- (nullable SSKProtoEnvelope *)envelope
{
    if (!_envelope) {
        NSError *error;
        SSKProtoEnvelope *_Nullable envelope = [[SSKProtoEnvelope alloc] initWithSerializedData:self.envelopeData
                                                                                          error:&error];
        if (error || envelope == nil) {
            OWSFailDebug(@"Could not parse proto: %@", error);
        } else {
            _envelope = envelope;
        }
    }
    return _envelope;
}

- (void)throws_acceptNewIdentityKey
{
    OWSAssertIsOnMainThread();

    if (self.errorType != TSErrorMessageWrongTrustedIdentityKey) {
        OWSLogError(@"Refusing to accept identity key for anything but a Key error.");
        return;
    }

    NSData *_Nullable newKey = [self throws_newIdentityKey];
    if (!newKey) {
        OWSFailDebug(@"Couldn't extract identity key to accept");
        return;
    }

    [[OWSIdentityManager shared] saveRemoteIdentity:newKey address:self.envelope.sourceAddress];

    // Decrypt this and any old messages for the newly accepted key
    NSArray<TSInvalidIdentityKeyReceivingErrorMessage *> *_Nullable messagesToDecrypt =
        [self.threadWithSneakyTransaction receivedMessagesForInvalidKey:newKey];
    [self decryptWithMessagesToDecrypt:messagesToDecrypt];
}

- (nullable NSData *)throws_newIdentityKey
{
    if (!self.envelope) {
        OWSLogError(@"Error message had no envelope data to extract key from");
        return nil;
    }
    if (!self.envelope.hasType) {
        OWSLogError(@"Error message envelope is missing type.");
        return nil;
    }
    if (self.envelope.unwrappedType != SSKProtoEnvelopeTypePrekeyBundle) {
        OWSLogError(@"Refusing to attempt key extraction from an envelope which isn't a prekey bundle");
        return nil;
    }

    NSData *pkwmData = self.envelope.content;
    if (!pkwmData) {
        OWSLogError(@"Ignoring acceptNewIdentityKey for empty message");
        return nil;
    }

    NSError *_Nullable error;
    NSData *_Nullable result = [[self class] identityKeyFromEncodedPreKeySignalMessage:pkwmData error:&error];
    if (!result) {
        OWSRaiseException(InvalidMessageException, @"%@", error.userErrorDescription);
    }
    return result;
}

- (NSString *)theirSignalId
{
    if (self.authorId) {
        return self.authorId;
    } else {
        // for existing messages before we were storing author id.
        return self.envelope.sourceE164;
    }
}

- (SignalServiceAddress *)theirSignalAddress
{
    OWSAssertDebug(self.envelope.sourceAddress != nil);

    return self.envelope.sourceAddress;
}

@end

NS_ASSUME_NONNULL_END
