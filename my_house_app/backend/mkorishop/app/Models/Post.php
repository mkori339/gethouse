<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Post extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'poster',
        'category',
        'type',
        'amount',
        'explanation',
        'region',
        'district',
        'street',
        'room_no',
        'status',
    ];

    public function user()
    {
        return $this->belongsTo(CustomUser::class, 'user_id');
    }

    public function images()
    {
        return $this->hasMany(PostImage::class, 'post_id');
    }
}
