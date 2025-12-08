from django.shortcuts import render, redirect
from django.contrib.auth.forms import UserCreationForm, AuthenticationForm
from django.contrib import messages
from django.contrib.auth import login, logout
from django.contrib.auth.decorators import login_required
from .models import RegistrationAttempt
from django.utils import timezone
from datetime import timedelta

def get_ip(request):
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0].strip()
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip

def public_view(request):
    ip = get_ip(request)
    udana = request.session.pop('udana', False)
    logout = request.session.pop('logout', False)
    one_minute_ago = timezone.now() - timedelta(minutes=1)
    
    if (not udana) and (not logout):
        recent_attempt = RegistrationAttempt.objects.filter(
            ip_address=ip,
            timestamp__gte=one_minute_ago
        ).exists()
    
        if recent_attempt:
            messages.error(request, 'Można zarejestrować jedno konto na minutę, poczekaj.')
            form = UserCreationForm()
            return render(request, 'public.html', {'form': form})

    if request.method == 'POST':
        form = UserCreationForm(request.POST)
        if form.is_valid():
            form.save()
            RegistrationAttempt.objects.create(ip_address=ip)
            messages.success(request, 'Rejestracja zakończona sukcesem! Możesz się teraz zalogować.')
            request.session['udana'] = True
            return redirect('public')
    else:
        form = UserCreationForm()

    return render(request, 'public.html', {'form': form})

def login_view(request):
    next_url = request.GET.get('next') or request.POST.get('next')
    if request.method == 'POST':
        form = AuthenticationForm(request, data=request.POST)
        if form.is_valid():
            user = form.get_user()
            login(request, user)
            messages.success(request, 'Zalogowano pomyślnie!')
            if next_url:
                return redirect(next_url)
            return redirect('private')
    else:
        form = AuthenticationForm()
    return render(request, 'login.html', {'form': form, 'next': next_url})

def logout_view(request):
    logout(request)
    messages.info(request, 'Wylogowano pomyślnie.')
    request.session['logout'] = True
    return redirect('public')

@login_required(login_url='login')
def private_view(request):
    return render(request, 'private.html')
