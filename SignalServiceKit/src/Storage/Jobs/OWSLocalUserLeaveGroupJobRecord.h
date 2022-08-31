//
//  Copyright (c) 2022 Open Whisper Systems. All rights reserved.
//

#import <SignalServiceKit/SSKJobRecord.h>

NS_ASSUME_NONNULL_BEGIN

@interface OWSLocalUserLeaveGroupJobRecord : SSKJobRecord

@property (nonatomic, readonly) NSString *threadId;
@property (nullable, nonatomic, readonly) NSString *replacementAdminUuid;
@property (nonatomic, readonly) BOOL waitForMessageProcessing;

- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithThreadId:(NSString *)threadId
            replacementAdminUuid:(nullable NSString *)replacementAdminUuid
        waitForMessageProcessing:(bool)waitForMessageProcessing
                           label:(NSString *)label NS_DESIGNATED_INITIALIZER;

- (nullable)initWithLabel:(NSString *)label NS_UNAVAILABLE;

- (instancetype)initWithGrdbId:(int64_t)grdbId
                      uniqueId:(NSString *)uniqueId
    exclusiveProcessIdentifier:(nullable NSString *)exclusiveProcessIdentifier
                  failureCount:(NSUInteger)failureCount
                         label:(NSString *)label
                        sortId:(unsigned long long)sortId
                        status:(SSKJobRecordStatus)status NS_UNAVAILABLE;

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run
// `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithGrdbId:(int64_t)grdbId
                      uniqueId:(NSString *)uniqueId
      exclusiveProcessIdentifier:(nullable NSString *)exclusiveProcessIdentifier
                    failureCount:(NSUInteger)failureCount
                           label:(NSString *)label
                          sortId:(unsigned long long)sortId
                          status:(SSKJobRecordStatus)status
            replacementAdminUuid:(nullable NSString *)replacementAdminUuid
                        threadId:(NSString *)threadId
        waitForMessageProcessing:(BOOL)waitForMessageProcessing
NS_DESIGNATED_INITIALIZER NS_SWIFT_NAME(init(grdbId:uniqueId:exclusiveProcessIdentifier:failureCount:label:sortId:status:replacementAdminUuid:threadId:waitForMessageProcessing:));

// clang-format on

// --- CODE GENERATION MARKER

@end

NS_ASSUME_NONNULL_END