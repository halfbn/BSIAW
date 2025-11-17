from django import forms
from .models import Comment

class CommentForm(forms.ModelForm):
    class Meta:
        model = Comment
        fields = ['author', 'content']
        exclude = ['author']
    def clean_content(self):
        comment = self.cleaned_data["content"]
        if len(comment)>400:
            raise forms.ValidationError("komentarz nie może być dłuższy niż 400 znaków")
        return comment
    
