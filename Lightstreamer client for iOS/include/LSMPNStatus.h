//
//  LSMPNStatus.h
//  Lightstreamer client for iOS
//

#ifndef Lightstreamer_client_for_iOS_LSMPNStatus_h
#define Lightstreamer_client_for_iOS_LSMPNStatus_h


/**
 * The LSMPNStatus enum contains the possible statuses of an MPN subscription.
 * It is returned by the <CODE>inquiryMPNStatus:</CODE> method of LSClient. It's
 * possible significant values are:<UL>
 * <LI>LSMPNStatusActive: the MPN subscription is active (if it has a trigger expression, it has not triggered yet);
 * <LI>LSMPNStatusTriggered: the MPN subscription is active and it has a trigger expression that has already triggered;
 * <LI>LSMPNStatusSuspended: the MPN subscription has been suspended due to invalidation of the device token by APNS Feedback Service.
 * </UL>
 * The <CODE>LSMPNStatusActive</CODE> value is the common status of an MPN subscription. If it has no trigger expression, 
 * it means the MPN subscription is sending its mobile push (i.e. remote) notifications as usual. If it has a trigger expression, 
 * it means the MPN subscription is waiting for it to trigger.
 * <BR/>In the <CODE>LSMPNStatusTriggered</CODE> status, the MPN subscription has already sent his only update and may safely be deactivated.
 * See <CODE>triggerExpression</CODE> of LSMPNInfo for more information.
 * <BR/>In the <CODE>LSMPNStatusSuspended</CODE> status, the subscription is not active but it will be reactivated as soon as
 * a device token change is notified to the Server. See <CODE>registrationForMPNSucceededWithToken:</CODE> of LSClient for more information.
 * Note that a suspended subscription, if not reactivated, may also be removed by the Server after a timeout.
 * <BR/>The special value <CODE>LSMPNStatusUnknown</CODE> is returned only when the <CODE>inquireMPNStatus:</CODE> is called inside a batch,
 * and means the operation has been deferred. The actual status will be returned upon batch commit.
 * <BR/>Note that a subscription that has been deactivated has also been deleted. Hence, there isn't a corresponding state;
 * rather, the <CODE>inquiryMPNStatus:</CODE> for such a subscription will fail.
 */
typedef enum {
	LSMPNStatusUnknown= 0,
	LSMPNStatusActive= 1,
	LSMPNStatusTriggered= 2,
	LSMPNStatusSuspended= 9
} LSMPNStatus;


#endif
