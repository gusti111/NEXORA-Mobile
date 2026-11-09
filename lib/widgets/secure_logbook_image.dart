import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/session_token_store.dart';

/// Displays a logbook photo through the authenticated private API endpoint.
class SecureLogbookImage extends StatefulWidget {
  const SecureLogbookImage({
    super.key,
    required this.logbookId,
    this.height = 220,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
  });

  final int logbookId;
  final double height;
  final double width;
  final BoxFit fit;

  @override
  State<SecureLogbookImage> createState() => _SecureLogbookImageState();
}

class _SecureLogbookImageState extends State<SecureLogbookImage> {
  late final Future<String?> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = SessionTokenStore.readToken();
  }

  Widget _placeholder({bool loading = false}) {
    return Container(
      height: widget.height,
      width: widget.width,
      alignment: Alignment.center,
      color: Colors.grey.shade200,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text(
              'Foto tidak dapat dimuat',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _tokenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _placeholder(loading: true);
        }

        final token = snapshot.data;
        if (snapshot.hasError || token == null || token.isEmpty) {
          return _placeholder();
        }

        return Image.network(
          ApiService.logbookPhotoUrl(widget.logbookId),
          headers: {
            'Accept': 'image/jpeg',
            'Authorization': 'Bearer $token',
          },
          height: widget.height,
          width: widget.width,
          fit: widget.fit,
          errorBuilder: (_, _, _) => _placeholder(),
        );
      },
    );
  }
}
