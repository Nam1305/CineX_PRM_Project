import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinex_application/features/characters/providers/character_provider.dart';
import 'package:cinex_application/shared/widgets/empty_state_widget.dart';
import '../widgets/character_card.dart';
import 'character_form_screen.dart';

class CharactersTab extends StatefulWidget {
  final int projectId;
  const CharactersTab({super.key, required this.projectId});

  @override
  State<CharactersTab> createState() => _CharactersTabState();
}

class _CharactersTabState extends State<CharactersTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CharacterProvider>().loadCharacters(widget.projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CharacterProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.characters.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.person_outline,
              message: 'Chưa có nhân vật nào.\nBấm nút + để thêm nhân vật đầu tiên.',
            );
          }
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final char = provider.characters[i];
                      return CharacterCard(
                        character: char,
                        onTap: () => _openForm(context, character: char),
                        onDelete: () async {
                          await provider.removeCharacter(char.id!);
                        },
                      );
                    },
                    childCount: provider.characters.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }

  void _openForm(BuildContext context, {character}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CharacterFormScreen(
          projectId: widget.projectId,
          character: character,
        ),
      ),
    );
  }
}
