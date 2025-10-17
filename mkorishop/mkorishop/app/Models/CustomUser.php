<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;

class CustomUser extends Authenticatable
{
    use HasFactory;

    protected $table = 'custom_users';

    protected $fillable = [
        'username',
        'email',
        'password',
        'phone',
        'role',
        'is_blocked',
        'api_token',
    ];

    protected $hidden = [
        'password',
        'api_token',
    ];

    // Relations
    public function posts()
    {
        return $this->hasMany(Post::class, 'user_id');
    }

    public function reports()
    {
        return $this->hasMany(Report::class, 'reporter_id');
    }
}
