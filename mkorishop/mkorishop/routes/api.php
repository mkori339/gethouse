<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ApiController;
// 
use Illuminate\Support\Facades\Storage;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

Route::get('storage/posts/{id}/{filename}', function ($id, $filename, Request $request) {
    $path = "posts/{$id}/{$filename}";

    if (!Storage::disk('public')->exists($path)) {
        abort(404);
    }

    $file = Storage::disk('public')->get($path);
    $type = Storage::disk('public')->mimeType($path);

    return response($file, 200)
        ->header('Content-Type', $type)
        ->header('Access-Control-Allow-Origin', '*'); 
});
//public
Route::post('/register', [ApiController::class, 'register']);
Route::post('/login', [ApiController::class, 'login']);
// Route::post('/report/agent', [ApiController::class, 'reportAgent']);
Route::post('/report/post', [ApiController::class, 'reportPost']);
Route::post('/agent/search', [ApiController::class, 'searchAgent']);
Route::post('/user/search_house', [ApiController::class, 'searchHouse']);
Route::get('/agents', [ApiController::class, 'listAgentsPublic']);
Route::get('/posts/public', [ApiController::class, 'viewAllPostsPublic']); // public
Route::get('/me', [ApiController::class, 'mee']);

// user
Route::post('/user/post', [ApiController::class, 'userPost']);
Route::post('/user/update_profile/{id}', [ApiController::class, 'updateProfile']);
Route::delete('/user/delete/{id}', [ApiController::class, 'deleteUser']);
Route::get('/user/view_profile/{id}', [ApiController::class, 'viewProfile']);
Route::post('/agent/requests', [ApiController::class, 'createAgent']);
Route::put('/agent/update/{id}', [ApiController::class, 'updateAgent']);
Route::delete('/agent/delete/{id}', [ApiController::class, 'deleteAgent']);
Route::post('/user/update_post/{id}', [ApiController::class, 'updateUserPost']);
Route::delete('/user/delete_post/{id}', [ApiController::class, 'deleteUserPost']);
Route::get('/user/view_post/{id}', [ApiController::class, 'viewUserPosts']);
Route::get('/user/view_postone/{id}', [ApiController::class, 'viewUserPostsone']);
// Likes
Route::post('/posts/{id}/like', [ApiController::class, 'toggleLike']);
Route::get('/posts/{id}/likes', [ApiController::class, 'getLikes']);

// Comments
Route::post('/posts/{id}/comments', [ApiController::class, 'addComment']);
Route::get('/posts/{id}/comments', [ApiController::class, 'getComments']);
Route::delete('/comments/{id}', [ApiController::class, 'deleteComment']);

// admin
Route::get('/agent/view/{id}', [ApiController::class, 'viewAgent']);//
Route::get('/admin/view_reports', [ApiController::class, 'adminViewReports']);//
Route::post('/admin/verify_post/{id}', [ApiController::class, 'adminVerifyPost']);//
Route::get('/admin/view', [ApiController::class, 'adminView']);//
Route::post('/admin/close_registration', [ApiController::class, 'adminCloseRegistration']);//
// Route::get('/admin/view_paid_posts', [ApiController::class, 'adminViewPaidPosts']);//
Route::get('/admin/view_unpaid_agents', [ApiController::class, 'adminViewUnpaidAgents']);//
Route::post('/admin/verify_agent/{id}', [ApiController::class, 'adminVerifyAgent']);//
Route::delete('/admin/delete_agent/{id}', [ApiController::class, 'adminDeleteAgent']);//
Route::get('/posts/unpaid', [ApiController::class, 'unpaidPosts']); // admin
Route::get('/users', [ApiController::class, 'viewAllUsers']); // admin
Route::post('/users/block/{id}', [ApiController::class, 'blockUser']); // admin

// contacts
// Route::post('/contacts', [ApiController::class, 'storeContact']);
// Route::get('/contacts', [ApiController::class, 'viewContacts']); // admin
// Route::get('/contacts/{id}', [ApiController::class, 'viewContact']); // admin


// chats
// Route::post('/messages/send', [ApiController::class, 'sendMessage']);
// Route::get('/messages/conversation/{userId}', [ApiController::class, 'getConversation']);
// Route::get('/messages/conversations', [ApiController::class, 'listConversations']);



