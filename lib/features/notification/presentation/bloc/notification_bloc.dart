import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/notification_usecases.dart';

abstract class NotificationEvent extends Equatable { const NotificationEvent(); @override List<Object?> get props => []; }
class LoadNotifications extends NotificationEvent { final String userId; const LoadNotifications(this.userId); @override List<Object> get props => [userId]; }
class MarkAsRead extends NotificationEvent { final String notifId; const MarkAsRead(this.notifId); @override List<Object> get props => [notifId]; }

abstract class NotificationState extends Equatable { const NotificationState(); @override List<Object?> get props => []; }
class NotificationInitial extends NotificationState {}
class NotificationLoading extends NotificationState {}
class NotificationsLoaded extends NotificationState { final List<Map<String, dynamic>> notifications; const NotificationsLoaded(this.notifications); @override List<Object> get props => [notifications]; }
class NotificationError extends NotificationState { final String message; const NotificationError(this.message); @override List<Object> get props => [message]; }

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetUserNotifications getUserNotifications; final MarkNotificationRead markNotificationRead;
  NotificationBloc({required this.getUserNotifications, required this.markNotificationRead}) : super(NotificationInitial()) {
    on<LoadNotifications>((e, emit) async { emit(NotificationLoading()); final r = await getUserNotifications(e.userId); r.fold((f) => emit(NotificationError(f.message)), (n) => emit(NotificationsLoaded(n))); });
    on<MarkAsRead>((e, emit) async { await markNotificationRead(e.notifId); });
  }
}
