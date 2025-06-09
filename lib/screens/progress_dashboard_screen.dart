import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/user_profile_provider.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(localizations.translate('progress_dashboard')),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _shareProgress(context),
          ),
        ],
      ),
      body: Consumer<UserProfileProvider>(
        builder: (context, userProvider, child) {
          final profile = userProvider.userProfile;
          
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: () => userProvider.refreshProfile(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(profile, localizations, theme),
                    const SizedBox(height: 24),
                    _buildStatsGrid(profile, localizations, theme),
                    const SizedBox(height: 24),
                    _buildProgressChart(profile, localizations, theme),
                    const SizedBox(height: 24),
                    _buildAchievements(profile, localizations, theme),
                    const SizedBox(height: 24),
                    _buildHealthBenefits(profile, localizations, theme),
                    const SizedBox(height: 24),
                    _buildMotivationalQuote(localizations, theme),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(UserProfile profile, AppLocalizations localizations, ThemeData theme) {
    final daysSmokeFree = profile.daysSmokeFree;
    final isPreQuit = profile.isInPreQuitPhase;
    final isQuitDay = profile.isOnQuitDay;
    
    return ScaleTransition(
      scale: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              isPreQuit ? Icons.calendar_today_rounded :
              isQuitDay ? Icons.celebration_rounded :
              Icons.favorite_rounded,
              size: 48,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              isPreQuit 
                  ? localizations.translate('days_until_quit_date')
                  : isQuitDay
                      ? localizations.translate('quit_day_today')
                      : localizations.translate('days_smoke_free'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPreQuit 
                  ? '${profile.daysUntilQuitDate}'
                  : isQuitDay
                      ? '🎉'
                      : '$daysSmokeFree',
              style: theme.textTheme.displayLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!isPreQuit && !isQuitDay) ...[
              const SizedBox(height: 8),
              Text(
                daysSmokeFree == 1 
                    ? localizations.translate('day')
                    : localizations.translate('days'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(UserProfile profile, AppLocalizations localizations, ThemeData theme) {
    final stats = [
      {
        'icon': Icons.attach_money_rounded,
        'title': localizations.translate('money_saved'),
        'value': '\$${profile.moneySaved.toStringAsFixed(2)}',
        'color': Colors.green,
      },
      {
        'icon': Icons.smoke_free_rounded,
        'title': localizations.translate('cigarettes_avoided'),
        'value': '${profile.cigarettesAvoided}',
        'color': Colors.blue,
      },
      {
        'icon': Icons.emoji_events_rounded,
        'title': localizations.translate('achievements'),
        'value': '${profile.achievementsUnlocked.length}',
        'color': Colors.orange,
      },
      {
        'icon': Icons.trending_up_rounded,
        'title': localizations.translate('streak'),
        'value': '${profile.daysSmokeFree}',
        'color': Colors.purple,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _slideAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (stat['color'] as Color).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      stat['icon'] as IconData,
                      size: 32,
                      color: stat['color'] as Color,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      stat['value'] as String,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: stat['color'] as Color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat['title'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgressChart(UserProfile profile, AppLocalizations localizations, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('weekly_progress'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _buildWeeklyChart(profile, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(UserProfile profile, ThemeData theme) {
    // Generate sample data for the last 7 days
    final days = List.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: 6 - index));
      final daysSinceQuit = profile.actualQuitDate != null 
          ? date.difference(profile.actualQuitDate!).inDays
          : 0;
      return {
        'day': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1],
        'value': daysSinceQuit >= 0 ? 1.0 : 0.0,
        'isToday': date.day == DateTime.now().day,
      };
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: days.map((day) {
        final height = (day['value'] as double) * 150 + 20;
        final isToday = day['isToday'] as bool;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 500 + days.indexOf(day) * 100),
              width: 24,
              height: height,
              decoration: BoxDecoration(
                color: isToday 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              day['day'] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday 
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAchievements(UserProfile profile, AppLocalizations localizations, ThemeData theme) {
    final achievements = [
      {
        'id': 'first_day',
        'title': localizations.translate('achievement_first_day'),
        'description': localizations.translate('achievement_first_day_desc'),
        'icon': Icons.star_rounded,
        'unlocked': profile.daysSmokeFree >= 1,
      },
      {
        'id': 'one_week',
        'title': localizations.translate('achievement_one_week'),
        'description': localizations.translate('achievement_one_week_desc'),
        'icon': Icons.calendar_view_week_rounded,
        'unlocked': profile.daysSmokeFree >= 7,
      },
      {
        'id': 'one_month',
        'title': localizations.translate('achievement_one_month'),
        'description': localizations.translate('achievement_one_month_desc'),
        'icon': Icons.calendar_month_rounded,
        'unlocked': profile.daysSmokeFree >= 30,
      },
      {
        'id': 'money_saver',
        'title': localizations.translate('achievement_money_saver'),
        'description': localizations.translate('achievement_money_saver_desc'),
        'icon': Icons.savings_rounded,
        'unlocked': profile.moneySaved >= 100,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('achievements'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...achievements.map((achievement) {
          final isUnlocked = achievement['unlocked'] as bool;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUnlocked 
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUnlocked 
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUnlocked 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      achievement['icon'] as IconData,
                      color: isUnlocked 
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement['title'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isUnlocked 
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          achievement['description'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUnlocked)
                    Icon(
                      Icons.check_circle_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHealthBenefits(UserProfile profile, AppLocalizations localizations, ThemeData theme) {
    final benefits = _getHealthBenefits(profile.daysSmokeFree, localizations);
    
    if (benefits.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('health_benefits'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...benefits.map((benefit) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      benefit,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMotivationalQuote(AppLocalizations localizations, ThemeData theme) {
    final quotes = [
      localizations.translate('quote_1'),
      localizations.translate('quote_2'),
      localizations.translate('quote_3'),
      localizations.translate('quote_4'),
    ];
    
    final randomQuote = quotes[DateTime.now().day % quotes.length];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
            theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            randomQuote,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<String> _getHealthBenefits(int daysSmokeFree, AppLocalizations localizations) {
    final benefits = <String>[];
    
    if (daysSmokeFree >= 1) {
      benefits.add(localizations.translate('benefit_24_hours'));
    }
    if (daysSmokeFree >= 3) {
      benefits.add(localizations.translate('benefit_3_days'));
    }
    if (daysSmokeFree >= 7) {
      benefits.add(localizations.translate('benefit_1_week'));
    }
    if (daysSmokeFree >= 30) {
      benefits.add(localizations.translate('benefit_1_month'));
    }
    if (daysSmokeFree >= 90) {
      benefits.add(localizations.translate('benefit_3_months'));
    }
    
    return benefits;
  }

  void _shareProgress(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final profile = context.read<UserProfileProvider>().userProfile;
    
    if (profile != null) {
      final message = localizations.translate('share_progress_message')
          .replaceAll('{days}', '${profile.daysSmokeFree}')
          .replaceAll('{money}', '\$${profile.moneySaved.toStringAsFixed(2)}')
          .replaceAll('{cigarettes}', '${profile.cigarettesAvoided}');
      
      // In a real app, you would use share_plus package
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translate('share_feature_coming_soon')),
        ),
      );
    }
  }
} 