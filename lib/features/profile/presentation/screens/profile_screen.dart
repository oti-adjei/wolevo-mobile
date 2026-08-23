import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../profile_providers.dart';
import '../widgets/addresses_section.dart';
import '../widgets/profile_section.dart';
import '../widgets/referrals_section.dart';
import '../widgets/settings_section.dart';
import '../widgets/support_section.dart';

/// One section of the account area, as its own route.
///
/// The web app kept all five behind `/profile?section=…` with a persistent
/// sidebar. On a phone each section is a push from the Account tab instead, so
/// only one is ever on screen and the back gesture does the obvious thing.
class ProfileSectionScreen extends ConsumerWidget {
  const ProfileSectionScreen({super.key, required this.section});

  final ProfileSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.account),
        ),
        title: Text(section.label),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.xl,
            AppSpace.gutter,
            AppSpace.section,
          ),
          children: [
            switch (section) {
              ProfileSection.profile => const ProfileInfoSection(),
              ProfileSection.addresses => const AddressesSection(),
              ProfileSection.referrals => const ReferralsSection(),
              ProfileSection.settings => const SettingsSection(),
              ProfileSection.support => const SupportSection(),
            },
          ],
        ),
      ),
    );
  }
}
