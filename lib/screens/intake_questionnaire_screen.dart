import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';
import '../utils/app_localizations.dart';
import 'home_screen.dart';

class IntakeQuestionnaireScreen extends StatefulWidget {
  const IntakeQuestionnaireScreen({super.key});

  @override
  State<IntakeQuestionnaireScreen> createState() => _IntakeQuestionnaireScreenState();
}

class _IntakeQuestionnaireScreenState extends State<IntakeQuestionnaireScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Form controllers and data
  final _cigarettesController = TextEditingController();
  NicotineDependence? _nicotineDependence;
  final List<String> _selectedReasons = [];
  final List<SupportNetworkType> _selectedSupport = [];
  QuitReadiness? _readinessToQuit;
  TimeOfDay? _dailyChatTime;
  DateTime? _quitDate;

  final List<String> _reasonsForQuitting = [
    'health_concerns',
    'save_money',
    'family_pressure',
    'social_stigma',
    'pregnancy',
    'doctor_advice',
    'smell_taste',
    'fitness_goals',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _cigarettesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeIntake();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0: // Cigarettes per day
        return _cigarettesController.text.isNotEmpty && 
               int.tryParse(_cigarettesController.text) != null &&
               int.parse(_cigarettesController.text) > 0;
      case 1: // Nicotine dependence
        return _nicotineDependence != null;
      case 2: // Reasons for quitting
        return _selectedReasons.isNotEmpty;
      case 3: // Support network
        return _selectedSupport.isNotEmpty;
      case 4: // Readiness to quit
        return _readinessToQuit != null;
      case 5: // Daily chat time
        return _dailyChatTime != null;
      case 6: // Quit date
        return _quitDate != null && _validateQuitDate(_quitDate) == null;
      default:
        return false;
    }
  }

  String? _validateQuitDate(DateTime? date) {
    if (date == null) return 'Please select a quit date';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);
    
    final daysDifference = selectedDate.difference(today).inDays;
    
    if (daysDifference < 7) {
      return 'Quit date must be at least 7 days from today';
    }
    
    if (daysDifference > 14) {
      return 'Quit date must be within 14 days from today';
    }
    
    return null;
  }

  Future<void> _completeIntake() async {
    setState(() => _isLoading = true);
    
    try {
      final userProfileProvider = context.read<UserProfileProvider>();
      
      // Update all intake data
      await userProfileProvider.updateCigarettesPerDay(int.parse(_cigarettesController.text));
      await userProfileProvider.updateNicotineDependence(_nicotineDependence!);
      await userProfileProvider.updateReasonsForQuitting(_selectedReasons);
      await userProfileProvider.updateSupportNetwork(_selectedSupport);
      await userProfileProvider.updateReadinessToQuit(_readinessToQuit!);
      await userProfileProvider.updateDailyChatTime(_dailyChatTime!);
      await userProfileProvider.updateQuitDate(_quitDate!);
      
      // Complete the intake process
      await userProfileProvider.completeIntakeQuestionnaire();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing intake: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(localizations.translate('intake_questionnaire')),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: _currentStep > 0 
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _previousStep,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: List.generate(
                    7,
                    (index) => Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_currentStep + 1} of 7',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildCigarettesStep(localizations, theme),
                _buildNicotineDependenceStep(localizations, theme),
                _buildReasonsStep(localizations, theme),
                _buildSupportNetworkStep(localizations, theme),
                _buildReadinessStep(localizations, theme),
                _buildChatTimeStep(localizations, theme),
                _buildQuitDateStep(localizations, theme),
              ],
            ),
          ),
          
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(localizations.translate('back')),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: _currentStep == 0 ? 1 : 2,
                  child: FilledButton(
                    onPressed: _canProceed() && !_isLoading ? _nextStep : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _currentStep == 6
                                ? localizations.translate('complete')
                                : localizations.translate('next'),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCigarettesStep(AppLocalizations localizations, ThemeData theme) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('cigarettes_per_day_title'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('cigarettes_per_day_description'),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _cigarettesController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              decoration: InputDecoration(
                labelText: localizations.translate('cigarettes_per_day'),
                hintText: '20',
                suffixText: localizations.translate('per_day'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.smoking_rooms_rounded),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNicotineDependenceStep(AppLocalizations localizations, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('nicotine_dependence_title'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('nicotine_dependence_description'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          ...NicotineDependence.values.map((dependence) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RadioListTile<NicotineDependence>(
                value: dependence,
                groupValue: _nicotineDependence,
                onChanged: (value) {
                  setState(() {
                    _nicotineDependence = value;
                  });
                },
                title: Text(localizations.translate('nicotine_${dependence.name}')),
                subtitle: Text(localizations.translate('nicotine_${dependence.name}_desc')),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReasonsStep(AppLocalizations localizations, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('reasons_for_quitting_title'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('reasons_for_quitting_description'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _reasonsForQuitting.length,
              itemBuilder: (context, index) {
                final reason = _reasonsForQuitting[index];
                final isSelected = _selectedReasons.contains(reason);
                
                return FilterChip(
                  label: Text(
                    localizations.translate('reason_$reason'),
                    style: TextStyle(
                      color: isSelected 
                          ? theme.colorScheme.onPrimary 
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedReasons.add(reason);
                      } else {
                        _selectedReasons.remove(reason);
                      }
                    });
                  },
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  selectedColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportNetworkStep(AppLocalizations localizations, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('support_network_title'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('support_network_description'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          ...SupportNetworkType.values.map((support) {
            final isSelected = _selectedSupport.contains(support);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CheckboxListTile(
                value: isSelected,
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedSupport.add(support);
                    } else {
                      _selectedSupport.remove(support);
                    }
                  });
                },
                title: Text(localizations.translate('support_${support.name}')),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReadinessStep(AppLocalizations localizations, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('readiness_title'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('readiness_description'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          ...QuitReadiness.values.map((readiness) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RadioListTile<QuitReadiness>(
                value: readiness,
                groupValue: _readinessToQuit,
                onChanged: (value) {
                  setState(() {
                    _readinessToQuit = value;
                  });
                },
                title: Text(localizations.translate('readiness_${readiness.name}')),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChatTimeStep(AppLocalizations localizations, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('chat_time_title'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('chat_time_description'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _dailyChatTime?.format(context) ?? localizations.translate('select_time'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _dailyChatTime ?? const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (time != null) {
                      setState(() {
                        _dailyChatTime = time;
                      });
                    }
                  },
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(localizations.translate('select_time')),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuitDateStep(AppLocalizations localizations, ThemeData theme) {
    final errorMessage = _validateQuitDate(_quitDate);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('quit_date_title'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('quit_date_description'),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: errorMessage == null 
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                        : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 48,
                        color: errorMessage == null 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _quitDate != null 
                            ? '${_quitDate!.day}/${_quitDate!.month}/${_quitDate!.year}'
                            : localizations.translate('select_date'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: errorMessage == null 
                              ? theme.colorScheme.primary 
                              : theme.colorScheme.error,
                        ),
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          errorMessage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _quitDate ?? DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now().add(const Duration(days: 7)),
                      lastDate: DateTime.now().add(const Duration(days: 14)),
                    );
                    if (date != null) {
                      setState(() {
                        _quitDate = date;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(localizations.translate('select_date')),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    localizations.translate('quit_date_validation_info'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 