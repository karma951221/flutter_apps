import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

import '../../common/widget/pawlog_primary_button.dart';
import '../../theme/pawlog_theme.dart';
import '../cubit/dog_list_cubit.dart';
import '../cubit/dog_list_state.dart';

class DogListPage extends StatelessWidget {
  const DogListPage({
    required this.onAddDog,
    required this.onOpenDog,
    super.key,
  });

  final VoidCallback onAddDog;
  final ValueChanged<String> onOpenDog;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<DogListCubit>()..start(),
    child: _DogListView(onAddDog: onAddDog, onOpenDog: onOpenDog),
  );
}

class _DogListView extends StatelessWidget {
  const _DogListView({required this.onAddDog, required this.onOpenDog});

  final VoidCallback onAddDog;
  final ValueChanged<String> onOpenDog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<DogListCubit>();

    return BlocBuilder<DogListCubit, DogListState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: Text(l10n.walkDogListTitle)),
        body: SafeArea(
          child: switch (state) {
            DogListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            DogListFailure(:final failure) => Center(
              child: AppPlaceholder(
                message: failure.localizedMessage(context),
                actionLabel: l10n.commonRetry,
                onAction: cubit.start,
              ),
            ),
            DogListLoaded(:final dogs) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: dogs.isEmpty
                      ? Center(
                          child: AppPlaceholder(
                            message: l10n.walkDogListEmptyTitle,
                            description: l10n.walkDogListEmptyMessage,
                          ),
                        )
                      : ListView.separated(
                          itemCount: dogs.length,
                          separatorBuilder: (_, _) => const Divider(
                            indent: PawlogSize.gutter,
                            endIndent: PawlogSize.gutter,
                          ),
                          itemBuilder: (context, index) {
                            final dog = dogs[index];
                            final photoPath = dog.photoPath;
                            final breed = dog.breed;
                            return AppListTile(
                              key: Key('walk-dog-list-tile-${dog.id}'),
                              leading: AppAvatar(
                                nickname: dog.name,
                                radius: PawlogSize.avatarMd,
                                imageFile: photoPath == null
                                    ? null
                                    : cubit.photoFile(photoPath),
                              ),
                              title: Text(
                                dog.name,
                                style: PawlogTextStyles.of(context).dogName,
                              ),
                              subtitle: breed == null ? null : Text(breed),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => onOpenDog(dog.id),
                            );
                          },
                        ),
                ),
                PawlogBottomAction(
                  child: PawlogPrimaryButton(
                    key: const Key('walk-dog-add-button'),
                    label: l10n.walkDogAddAction,
                    onPressed: onAddDog,
                  ),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}
