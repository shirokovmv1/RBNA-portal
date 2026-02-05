from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    UserViewSet, ProjectViewSet, ContractorViewSet,
    ContractViewSet, CostItemViewSet, UnitRateViewSet,
    PaymentViewSet, ReportViewSet
)

router = DefaultRouter()
router.register(r'users', UserViewSet, basename='user')
router.register(r'projects', ProjectViewSet, basename='project')
router.register(r'contractors', ContractorViewSet, basename='contractor')
router.register(r'contracts', ContractViewSet, basename='contract')
router.register(r'cost-items', CostItemViewSet, basename='costitem')
router.register(r'unit-rates', UnitRateViewSet, basename='unitrate')
router.register(r'payments', PaymentViewSet, basename='payment')
router.register(r'reports', ReportViewSet, basename='report')

urlpatterns = [
    path('', include(router.urls)),
]
