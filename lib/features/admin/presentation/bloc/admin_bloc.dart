import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/admin_usecases.dart';

abstract class AdminEvent extends Equatable { const AdminEvent(); @override List<Object?> get props => []; }
class LoadAllPartners extends AdminEvent {}
class ApprovePartnerRequested extends AdminEvent { final String partnerId; const ApprovePartnerRequested(this.partnerId); @override List<Object> get props => [partnerId]; }
class SuspendPartnerRequested extends AdminEvent { final String partnerId; const SuspendPartnerRequested(this.partnerId); @override List<Object> get props => [partnerId]; }
class LoadPlatformAnalytics extends AdminEvent {}
class LoadFoodWasteData extends AdminEvent {}
class SendBroadcast extends AdminEvent { final String title; final String body; const SendBroadcast({required this.title, required this.body}); @override List<Object> get props => [title, body]; }

abstract class AdminState extends Equatable { const AdminState(); @override List<Object?> get props => []; }
class AdminInitial extends AdminState {}
class AdminLoading extends AdminState {}
class PartnersLoaded extends AdminState { final List<Map<String, dynamic>> partners; const PartnersLoaded(this.partners); @override List<Object> get props => [partners]; }
class AnalyticsLoaded extends AdminState { final Map<String, dynamic> data; const AnalyticsLoaded(this.data); @override List<Object> get props => [data]; }
class FoodWasteLoaded extends AdminState { final Map<String, dynamic> data; const FoodWasteLoaded(this.data); @override List<Object> get props => [data]; }
class BroadcastSent extends AdminState {}
class AdminActionSuccess extends AdminState { final String message; const AdminActionSuccess(this.message); @override List<Object> get props => [message]; }
class AdminError extends AdminState { final String message; const AdminError(this.message); @override List<Object> get props => [message]; }

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final GetAllPartners getAllPartners; final ApprovePartner approvePartner; final SuspendPartner suspendPartner;
  final GetPlatformAnalytics getPlatformAnalytics; final GetFoodWasteData getFoodWasteData; final BroadcastNotification broadcastNotification;
  AdminBloc({required this.getAllPartners, required this.approvePartner, required this.suspendPartner, required this.getPlatformAnalytics, required this.getFoodWasteData, required this.broadcastNotification}) : super(AdminInitial()) {
    on<LoadAllPartners>((e, emit) async { emit(AdminLoading()); final r = await getAllPartners(); r.fold((f) => emit(AdminError(f.message)), (p) => emit(PartnersLoaded(p))); });
    on<ApprovePartnerRequested>((e, emit) async { emit(AdminLoading()); final r = await approvePartner(e.partnerId); r.fold((f) => emit(AdminError(f.message)), (_) => emit(const AdminActionSuccess('Mitra disetujui'))); });
    on<SuspendPartnerRequested>((e, emit) async { emit(AdminLoading()); final r = await suspendPartner(e.partnerId); r.fold((f) => emit(AdminError(f.message)), (_) => emit(const AdminActionSuccess('Mitra ditangguhkan'))); });
    on<LoadPlatformAnalytics>((e, emit) async { emit(AdminLoading()); final r = await getPlatformAnalytics(); r.fold((f) => emit(AdminError(f.message)), (d) => emit(AnalyticsLoaded(d))); });
    on<LoadFoodWasteData>((e, emit) async { emit(AdminLoading()); final r = await getFoodWasteData(); r.fold((f) => emit(AdminError(f.message)), (d) => emit(FoodWasteLoaded(d))); });
    on<SendBroadcast>((e, emit) async { emit(AdminLoading()); final r = await broadcastNotification(BroadcastParams(title: e.title, body: e.body)); r.fold((f) => emit(AdminError(f.message)), (_) => emit(BroadcastSent())); });
  }
}
