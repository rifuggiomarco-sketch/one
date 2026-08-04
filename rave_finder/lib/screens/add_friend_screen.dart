import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/bonded_friend.dart';
import '../services/bonding_service.dart';

const _palette = <Color>[
  Colors.redAccent,
  Colors.blueAccent,
  Colors.greenAccent,
  Colors.orangeAccent,
  Colors.purpleAccent,
  Colors.cyanAccent,
  Colors.pinkAccent,
  Colors.yellowAccent,
  Colors.tealAccent,
  Colors.indigoAccent,
];

/// Lets the user share their own bonding code with a friend before the
/// event, and bond a friend by typing in the code they were given -
/// standing in for the necklaces' NFC "touch crystal" bonding step,
/// which needs dedicated hardware this app doesn't have.
class AddFriendScreen extends StatefulWidget {
  final int myShortId;
  final BondingService bonding;

  const AddFriendScreen({super.key, required this.myShortId, required this.bonding});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  Color _selectedColor = _palette.first;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _bond() async {
    final name = _nameController.text.trim();
    final shortId = codeToShortId(_codeController.text);

    if (name.isEmpty) {
      _showError('Inserisci un nome per il tuo amico.');
      return;
    }
    if (shortId == null) {
      _showError('Codice non valido: deve essere di 8 caratteri (es. A1B2C3D4).');
      return;
    }
    if (shortId == widget.myShortId) {
      _showError('Non puoi bondare te stesso.');
      return;
    }

    final added = await widget.bonding.addFriend(
      shortId: shortId,
      name: name,
      color: _selectedColor,
    );
    if (!added) {
      _showError('Hai già bondato un amico con questo codice.');
      return;
    }
    if (mounted) Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final myCode = shortIdToCode(widget.myShortId);
    return Scaffold(
      appBar: AppBar(title: const Text('Aggiungi amico')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Il tuo codice', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Condividilo con un amico prima del festival: lui lo inserirà '
            'nella sua app per bondarti.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    myCode,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 4, fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(text: 'Bondiamoci su RaveFinder! Il mio codice è: $myCode'),
                ),
                icon: const Icon(Icons.share),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text('Bonda un amico', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 8,
            decoration: const InputDecoration(
              labelText: 'Codice amico',
              hintText: 'es. A1B2C3D4',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text('Colore', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final color in _palette)
                GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: CircleAvatar(
                    backgroundColor: color,
                    radius: 20,
                    child: _selectedColor == color
                        ? const Icon(Icons.check, color: Colors.black)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _bond,
            icon: const Icon(Icons.link),
            label: const Text('Bonda'),
          ),
        ],
      ),
    );
  }
}
