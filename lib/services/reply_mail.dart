import 'package:enough_mail/enough_mail.dart';
import 'package:flutter/material.dart';
import 'package:iitk_mail_client/EmailCache/models/email.dart';
import 'package:iitk_mail_client/models/advanced_settings_model.dart';
import 'package:iitk_mail_client/services/email_fetch.dart';
import 'package:iitk_mail_client/services/save_mails_to_objbox.dart';

class EmailReply {
  static Future<void> replyEmail({
    required EmailSettingsModel emailSettings,
    required String username,
    required String password,
    required Email originalMessage,
    required String replyBody,
    required Function(String, Color) onResult,
  }) async {
    logger.i('Starting replyEmail function');
    final String serverName = emailSettings.smtpServer;
    final int port = int.parse(emailSettings.smtpPort);
    final client = SmtpClient('enough_mail', isLogEnabled: false);
    try {
      await client.connectToServer(serverName, port, isSecure: port == 465);
      await client.ehlo();
      logger.i('Connected and authenticated');

      await client.authenticate(username, password, AuthMechanism.plain);
      // logger.i("email $username" );
      MimeMessage originalMimeMessage = await EmailService.fetchMailByUid(
          uniqueId: int.parse(originalMessage.uniqueId.toString()),
          username: username,
          password: password);
      logger.i(originalMimeMessage);
      final builder = MessageBuilder.prepareReplyToMessage(
        originalMimeMessage,
        MailAddress(username, '$username@${emailSettings.domain}'),
      );
      final originalBody = originalMessage.body;
      final newBody = "$replyBody\n\n----Original Message----\n\n$originalBody";

      // Combine reply body with the quoted original message
      builder.text = newBody;

      logger.i('Combined Body:\n${builder.text}');
      //builder.text=replyBody;

      final mimeMessage = builder.buildMimeMessage();

      logger.i(mimeMessage.decodeTextPlainPart());

      final sendResponse = await client.sendMessage(mimeMessage);

      if (sendResponse.isOkStatus) {
        onResult('Reply sent successfully', Colors.green);
      } else {
        onResult(
            'Failed to send reply: Failed to establish connection with server',
            Colors.red);
      }
    } catch (e) {
      onResult('Failed to send reply: $e', Colors.red);
      logger.e('Error: $e');
      logger.i(e);
    } finally {
      await client.quit();
    }
  }
}
