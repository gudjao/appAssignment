//
//  ListCellNode.m
//  LykAssignment
//
//  Created by Juston Paul Alcantara on 07/11/2017.
//  Copyright © 2017 Juston Paul Alcantara. All rights reserved.
//

#import "ListCellNode.h"

@implementation ListCellNode {
    NSDictionary *_attrsNameText;
    NSDictionary *_attrsOtherText;
}

- (instancetype)init {
    self = [super init];
    if(self) {
        self.automaticallyManagesSubnodes = YES;
        
        self.profileImageNode = [[ASNetworkImageNode alloc] init];
        self.profileImageNode.placeholderColor = [UIColor colorWithRandomFlatColorOfShadeStyle:UIShadeStyleLight];
        self.profileImageNode.imageModificationBlock = ASImageNodeRoundBorderModificationBlock(0.0f, nil);
        
        // Attrs
        _attrsNameText = @{
                           NSFontAttributeName : [UIFont boldSystemFontOfSize:16.0f],
                           NSForegroundColorAttributeName : [UIColor flatBlackColorDark]
                           };
        
        _attrsOtherText = @{
                            NSFontAttributeName : [UIFont systemFontOfSize:15.0f],
                            NSForegroundColorAttributeName : [UIColor flatBlackColor]
                            };
        
        _nameTextNode = [[ASTextNode alloc] init];
        _nameTextNode.maximumNumberOfLines = 2;
        
        _emailTextNode = [[ASTextNode alloc] init];
        _emailTextNode.maximumNumberOfLines = 1;
        
        _phoneTextNode = [[ASTextNode alloc] init];
        _phoneTextNode.maximumNumberOfLines = 1;
        
        _inviteButtonNode = [[ASButtonNode alloc] init];
        [_inviteButtonNode setTitle:@"Invite"
                           withFont:[UIFont boldSystemFontOfSize:14.0f]
                          withColor:[UIColor whiteColor]
                           forState:UIControlStateNormal];
        _inviteButtonNode.backgroundColor = [UIColor flatBlueColor];
        _inviteButtonNode.hitTestSlop = UIEdgeInsetsMake(-5, -10, -5, -10);
        _inviteButtonNode.contentEdgeInsets = UIEdgeInsetsMake(5, 10, 5, 10);
        _inviteButtonNode.cornerRadius = 4.0f;
        [_inviteButtonNode addTarget:self
                              action:@selector(sendInvite)
                    forControlEvents:ASControlNodeEventTouchUpInside];
        
        _socialType = @"";
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize {
    // Image
    ASRatioLayoutSpec *ratioProfileImage = [ASRatioLayoutSpec ratioLayoutSpecWithRatio:1.0f
                                                                                 child:self.profileImageNode];
    ratioProfileImage.style.flexBasis = ASDimensionMakeWithFraction(0.16f);
    ratioProfileImage.style.minWidth = ASDimensionMake(40.0f);
    ratioProfileImage.style.maxWidth = ASDimensionMake(100.0f);
    
    // Text
    if(self.phoneTextNode.attributedText.string.length > 0) {
        self.phoneTextNode.style.spacingAfter = 10.0f;
    }
    
    ASStackLayoutSpec *stackEmailPhone = [ASStackLayoutSpec
                                          stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                          spacing:0.0f
                                          justifyContent:ASStackLayoutJustifyContentStart
                                          alignItems:ASStackLayoutAlignItemsStretch
                                          children:@[self.phoneTextNode,
                                                     self.emailTextNode]];
    
    ASStackLayoutSpec *stackNameWithEmailPhone = [ASStackLayoutSpec
                                                  stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
                                                  spacing:10.0f
                                                  justifyContent:ASStackLayoutJustifyContentStart
                                                  alignItems:ASStackLayoutAlignItemsStretch
                                                  children:@[self.nameTextNode,
                                                             stackEmailPhone]];
    
    // Content
    ASLayoutSpec *spacer = [ASLayoutSpec new];
    spacer.style.flexGrow = 1.0f;
    
    ratioProfileImage.style.alignSelf = ASStackLayoutAlignSelfCenter;
    self.inviteButtonNode.style.alignSelf = ASStackLayoutAlignSelfCenter;
    stackNameWithEmailPhone.style.flexShrink = 1.0f;
    
    ASStackLayoutSpec *stackMain = [ASStackLayoutSpec
                                    stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                    spacing:10.0f
                                    justifyContent:ASStackLayoutJustifyContentStart
                                    alignItems:ASStackLayoutAlignItemsStretch
                                    children:@[ratioProfileImage,
                                               stackNameWithEmailPhone,
                                               spacer,
                                               self.inviteButtonNode]];
    
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(10, 15, 10, 15)
                                                  child:stackMain];
}

// Name
- (void)setNameText:(NSString *)nameText {
    if (ASObjectIsEqual(_nameText, nameText)) return;
    
    _nameText = [nameText copy];
    
    if (_nameText == nil || _nameText.length == 0) {
        _nameTextNode.attributedText = [[NSAttributedString alloc] initWithString:@"<Unknown Name>"
                                                                       attributes:_attrsNameText];
        [self setNeedsLayout];
        return;
    }
    
    _nameTextNode.attributedText = [[NSAttributedString alloc] initWithString:self.nameText
                                                                   attributes:_attrsNameText];
    [self setNeedsLayout];
}

// Email
- (void)setEmailText:(NSString *)emailText {
    if (ASObjectIsEqual(_emailText, emailText)) return;
    
    _emailText = [emailText copy];
    
    if (_emailText == nil) {
        _emailTextNode.attributedText = nil;
        return;
    }
    
    _emailTextNode.attributedText = [[NSAttributedString alloc] initWithString:self.emailText
                                                                    attributes:_attrsOtherText];
    [self setNeedsLayout];
}

// Phone
- (void)setPhoneText:(NSString *)phoneText {
    if (ASObjectIsEqual(_phoneText, phoneText)) return;
    
    _phoneText = [phoneText copy];
    
    if (_phoneText == nil) {
        _phoneTextNode.attributedText = nil;
        return;
    }
    
    _phoneTextNode.attributedText = [[NSAttributedString alloc] initWithString:self.phoneText
                                                                    attributes:_attrsOtherText];
    [self setNeedsLayout];
}

- (void)didLoad {
    [super didLoad];
    
    // Initialize the service object.
    self.service = [[GTLRGmailService alloc] init];
    self.service.authorizer = [[GIDSignIn sharedInstance] currentUser].authentication.fetcherAuthorizer;
}

#pragma mark - Invite

- (void)sendInvite {
    
    if(self.emailText.length > 0 || self.emailText != nil) {
        [self sendMail];
    }
    
    // Push notifications
    if(self.userId == nil || self.userId.length == 0) {
        return;
    }
    
    NSString *urlString = @"https://onesignal.com/api/v1/notifications";
    
    NSString *inviteMessage = @"You have been invited";
    if([self.socialType isEqualToString:@"Google"]) {
        inviteMessage = [NSString stringWithFormat:@"You have been invited by user: %@", [[GIDSignIn sharedInstance] currentUser].profile.givenName];
    } else if([self.socialType isEqualToString:@"Facebook"]) {
        inviteMessage = [NSString stringWithFormat:@"You have been invited by user ID: %@", [FBSDKAccessToken currentAccessToken].userID];
    }
    
    NSDictionary *params = @{
                             @"app_id" : @"9fd78eb0-d757-44b0-be3b-21fff01428c6",
                             @"contents" : @{
                                     @"en" : inviteMessage
                                     },
                             @"filters" : @[
                                     @{
                                         @"field": @"tag",
                                         @"key": [NSString stringWithFormat:@"lykKey%@", self.socialType],
                                         @"relation": @"=",
                                         @"value": self.userId
                                         
                                         }
                                     ]
                             };
    
    NSLog(@"Send to userId: %@", self.userId);
    
    // 292 - 107856047367683995163
    // 29 -  103970934315969002734
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager.requestSerializer setValue:@"Basic MTYyOTMyOTUtYjM4Ny00MmM4LTg1NmYtMWQzNmYzODkyNDU4" forHTTPHeaderField:@"Authorization"];
    
    [manager POST:urlString
       parameters:params
         progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              NSLog(@"Success");
          } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              NSLog(@"Failed");
          }];
}

- (void)sendMail {
    GTLRGmail_Message *message = [[GTLRGmail_Message alloc] init];
    message.raw = GTLREncodeWebSafeBase64([self getFormattedRawMessage]);
    
    GTLRGmailQuery_UsersMessagesSend *querySend = [GTLRGmailQuery_UsersMessagesSend queryWithObject:message
                                                                                             userId:@"me"
                                                                                   uploadParameters:nil];
    
    [self.service executeQuery:querySend
             completionHandler:^(GTLRServiceTicket * _Nonnull callbackTicket, id  _Nullable object, NSError * _Nullable callbackError) {
                 NSLog(@"Object: %@", object);
                 NSLog(@"%@", [[NSString alloc] initWithData:callbackError.userInfo[@"data"] encoding:NSUTF8StringEncoding]);
             }];
}

- (NSData *)getFormattedRawMessage
{
    // Date string
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z";
    NSString *strDate = [dateFormatter stringFromDate:[NSDate date]];
    NSString *finalDate = [NSString stringWithFormat:@"Date: %@\r\n", strDate];
    
    // From string
    NSString *from = [NSString stringWithFormat:@"From: %@\r\n", [[GIDSignIn sharedInstance] currentUser].profile.email];
    
    // To string
    NSString *to = [NSString stringWithFormat:@"To: <%@>\r\n", self.emailText];
    
    // CC string
    NSString *cc = @"";
    
    // BCC string
    NSString *bcc = @"";
    
    // Subject string
    NSString *subject = @"Subject: Lyk Assingment\r\n\r\n";
    
    // Body string
    NSString *body = [NSString stringWithFormat:@"Hello,\nYou have been invited. \n-%@. \r\n", [[GIDSignIn sharedInstance] currentUser].profile.givenName];
    
    // Final string to be returned
    NSString *rawMessage = @"";
    
    // Send as "multipart/mixed"
    NSString *contentTypeMain = @"Content-Type: multipart/mixed; boundary=\"project\"\r\n";
    
    // Reusable Boundary string
    NSString *boundary = @"\r\n--project\r\n";
    
    // Body string
    NSString *contentTypePlain = @"Content-Type: text/plain; charset=\"UTF-8\"\r\n";
    
    // Combine strings from "finalDate" to "body"
    rawMessage = [[[[[[[[[contentTypeMain stringByAppendingString:finalDate] stringByAppendingString:from]stringByAppendingString:to]stringByAppendingString:cc]stringByAppendingString:bcc]stringByAppendingString:subject]stringByAppendingString:boundary]stringByAppendingString:contentTypePlain]stringByAppendingString:body];
    
    // End string
    rawMessage = [rawMessage stringByAppendingString:@"\r\n--project--"];
    
    return [rawMessage dataUsingEncoding:NSUTF8StringEncoding];
}

@end
