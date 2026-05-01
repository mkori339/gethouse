<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    use HasFactory;

    protected $fillable = [
        'sender_id',
        'receiver_id',
        'message',
        'is_read',
    ];

    public function sender()
    {
        return $this->belongsTo(CustomUser::class, 'sender_id');
    }

    public function receiver()
    {
        return $this->belongsTo(CustomUser::class, 'receiver_id');
    }
}
