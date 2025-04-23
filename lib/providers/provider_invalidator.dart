import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuntium_mobile/providers/data_provider.dart';

class ProviderInvalidator {
  static void invalidateAll(WidgetRef ref) {
    print('all providers will be invalidated');
    ref.invalidate(topicsProvider);
    ref.invalidate(featuredCardProvider);
    ref.invalidate(normalCardProvider);
    ref.invalidate(discoverContentProvider);
    ref.invalidate(bookmarkContentProvider);
    ref.invalidate(reditContentProvider);
    ref.invalidate(commentsContentProvider);
    ref.invalidate(postContentProvider);
    ref.invalidate(yourWorksProvider);
    ref.invalidate(userDataProfile);
    ref.invalidate(latestTermlyProvider);
    ref.invalidate(allTermlyProvider);
    ref.invalidate(membersProvider);
    ref.invalidate(postNotificationsProvider);
    ref.invalidate(sectionProvider);
    ref.invalidate(topicProvider);
    ref.invalidate(topicDataProvider);
    ref.invalidate(taskProvider);
    ref.invalidate(memberTasksProvider);
    ref.invalidate(memberListProvider);
    ref.invalidate(taskWrittenProvider);
    ref.invalidate(timelineProvider);
    ref.invalidate(allSectionTasksProvider);
    ref.invalidate(retImagesProvider);
    ref.invalidate(singleViewTopicContent);
    ref.invalidate(viewAllImageInParent);
    ref.invalidate(userSectionProvider);

    print('all providers have been invalidated');
  }
}
