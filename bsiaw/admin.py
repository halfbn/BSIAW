from django.contrib import admin
from django.contrib.sessions.models import Session

# Rejestracja modelu Session w panelu admin
@admin.register(Session)
class SessionAdmin(admin.ModelAdmin):
    list_display = ('session_key', 'get_user', 'expire_date', 'get_decoded')
    readonly_fields = ('session_key', 'session_data', 'expire_date', 'get_decoded')

    def get_user(self, obj):
        from django.contrib.auth.models import User
        import json
        try:
            data = obj.get_decoded()
            user_id = data.get('_auth_user_id')
            if user_id:
                user = User.objects.get(pk=user_id)
                return user.username
        except:
            return None
        return None
    get_user.short_description = 'Użytkownik'

    def get_decoded(self, obj):
        return obj.get_decoded()
    get_decoded.short_description = 'Session Data'
