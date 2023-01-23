import 'dart:async';

import 'package:djangoflow_fcm/src/data/djangoflow_fcm_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'djangoflow_fcm_event.dart';
import 'djangoflow_fcm_state.dart';

export 'djangoflow_fcm_event.dart';
export 'djangoflow_fcm_state.dart';

class DjangoflowFCMBloc extends Bloc<DjangoflowFCMEvent, DjangoflowFCMState> {
  final DjangoflowFCMRepository repository;

  DjangoflowFCMBloc(this.repository) : super(const DjangoflowFCMState()) {
    on<DjangoflowFCMOnMessageReceived>(_onMessageReceived);
    on<DjangoflowFCMOnTokenReceived>(_onTokenReceived);
    on<DjangoflowFCMTokenRequested>(_getToken);
    on<DjangoflowFCMInitialMessageRequested>(_getIntiailMessage);

    _foregroundRemoteMessageSubscription =
        repository.getForegroundRemoteMessageStream().listen(_onMessage);

    _backroundRemoteMessageTappedSubscription =
        repository.getBackgroundRemoteMessageTappedStream().listen(_onMessage);
  }

  late StreamSubscription<RemoteMessage> _foregroundRemoteMessageSubscription;
  late StreamSubscription<RemoteMessage>
      _backroundRemoteMessageTappedSubscription;

  void _onMessageReceived(DjangoflowFCMOnMessageReceived event,
          Emitter<DjangoflowFCMState> emit) =>
      emit(
        state.copyWith(
          remoteMessage: event.remoteMessage,
        ),
      );

  void _onTokenReceived(DjangoflowFCMOnTokenReceived event,
          Emitter<DjangoflowFCMState> emit) =>
      emit(
        state.copyWith(
          token: event.token,
          notificationAuthorizationStatus: AuthorizationStatus.authorized,
        ),
      );

  Future<void> _getToken(DjangoflowFCMTokenRequested event,
      Emitter<DjangoflowFCMState> emit) async {
    final isSupported = await repository.isSupported();
    if (isSupported) {
      final permission = await repository.requestNotificationPermission();
      if (permission.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await repository.getToken();
        add(DjangoflowFCMOnTokenReceived(token));
      } else {
        emit(
          state.copyWith(
            notificationAuthorizationStatus: permission.authorizationStatus,
          ),
        );
      }
    }
  }

  Future<void> _getIntiailMessage(DjangoflowFCMInitialMessageRequested event,
      Emitter<DjangoflowFCMState> emit) async {
    final initialMessage = await repository.getInitialRemoteMessage();
    if (initialMessage != null) {
      add(DjangoflowFCMOnMessageReceived(initialMessage));
    }
  }

  void _onMessage(RemoteMessage remoteMessage) =>
      add(DjangoflowFCMOnMessageReceived(remoteMessage));

  @override
  Future<void> close() async {
    _foregroundRemoteMessageSubscription.cancel();
    _backroundRemoteMessageTappedSubscription.cancel();
    super.close();
  }
}