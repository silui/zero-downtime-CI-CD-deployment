from django.urls import path

from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('test/<int:multipler>', views.test, name='test'),

]