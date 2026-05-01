<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Agent extends Model
{
    use HasFactory;

    protected $fillable = [
        'id',
        'agent_name',
        'region',
        'phone',
        'status',
        'created_by',
    ];

    public function creator()
    {
        return $this->belongsTo(CustomUser::class, 'created_by');
    }
}
