//
//  LSPushClientException.h
//  Lightstreamer client for iOS
//

#import "LSException.h"


/**
 * The LSPushClientException class incapsulates exceptions thrown due to client-side problems, such as invalid parameters for a request.
 */
@interface LSPushClientException : LSException {}


#pragma mark -
#pragma mark Initialization

/**
 * Creates and raises an LSPushClientException object with specified parameters.
 *
 * @param reason Reason of the exception.
 *
 * @return The LSPushClientException object.
 */
+ (LSPushClientException *) clientExceptionWithReason:(NSString *)reason, ...;

/**
 * Initializes an LSPushClientException object with specified parameters.
 *
 * @param reason Reason of the exception.
 *
 * @return The LSPushClientException object.
 */
- (id) initWithReason:(NSString *)reason, ...;

/**
 * Initializes an LSPushClientException object with specified parameters.
 *
 * @param reason Reason of the exception.
 * @param arguments Variable argument list of parameters.
 *
 * @return The LSPushClientException object.
 */
- (id) initWithReason:(NSString *)reason arguments:(va_list)arguments;


@end
