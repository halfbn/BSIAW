from django.urls import path
from . import views

urlpatterns = [
    path('', views.comment_view, name='comment'),
]