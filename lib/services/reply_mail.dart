import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:test_drive/EmailCache/models/email.dart';
import 'package:test_drive/services/email_fetch.dart';
import 'package:test_drive/services/save_mails_to_objbox.dart';

class EmailReply {
  static Future<void> replyEmail({
    required String username,
    required String password,
    required Email originalMessage,
    required String replyBody,
    required Function(String, Color) onResult,
  }) async {
    final client = SmtpClient('enough_mail', isLogEnabled: false);
    try {
      await client.connectToServer('mmtp.iitk.ac.in', 465, isSecure: true);
      await client.ehlo();

      await client.authenticate(username, password, AuthMechanism.plain);
      // logger.i("email $username" );
      MimeMessage originalMimeMessage =  await  EmailService.fetchMailByUid(
        uniqueId: int.parse(originalMessage.uniqueId), 
        username: username, 
        password: password
        );
      // logger.i(originalMimeMessage);
         final builder = MessageBuilder.prepareReplyToMessage(
        originalMimeMessage,
        MailAddress(username, '$username@iitk.ac.in'),
        quoteOriginalText: true,
      );
        
      // Add reply body
      final replyHeader = MessageBuilder.fillTemplate(MailConventions.defaultReplyHeaderTemplate, originalMimeMessage);
      final quotedHtml =
            '<p>$replyBody</p><blockquote><br/>$replyHeader<br/>${originalMimeMessage.decodeTextHtmlPart()}</blockquote>';
      final quotedPlainText = MessageBuilder.quotePlainText(replyHeader, originalMimeMessage.decodeTextPlainPart());
      final textBody = replyBody+"\n\n"+ quotedPlainText ;
      builder.addTextPlain(textBody);
      builder.addTextHtml(quotedHtml);
      final mimeMessage = builder.buildMimeMessage();
      final sendResponse = await client.sendMessage(mimeMessage);

      if (sendResponse.isOkStatus) {
        onResult('Reply sent successfully', Colors.green);
      } else {
        onResult('Failed to send reply: Failed to establish connection with server', Colors.red);
      }
    } catch (e) {
      onResult('Failed to send reply: $e', Colors.red);
    } finally {
      await client.quit();
    }
  }
}
