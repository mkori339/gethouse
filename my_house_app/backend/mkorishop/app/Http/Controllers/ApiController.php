<?php

namespace App\Http\Controllers;
use Illuminate\Support\Facades\Storage;
use App\Models\PostImage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use App\Models\CustomUser;
use App\Models\Post;
use App\Models\Agent;
use App\Models\Report;
use App\Models\Contact;
use App\Models\Message;
use App\Models\Setting;
use App\Models\Like;
use App\Models\Comment;

class ApiController extends Controller
{
    // Helper: Authenticate user from Bearer token
    private function authUser(Request $request)
    {
        $header = $request->header('Authorization');
        if (!$header || !str_starts_with($header, 'Bearer ')) {
            return null;
        }
        $token = trim(substr($header, 7));
        return CustomUser::where('api_token', $token)->first();
    }

    private function userPayload(CustomUser $user): array
    {
        return [
            'id' => $user->id,
            'username' => $user->username,
            'email' => $user->email,
            'phone' => $user->phone,
            'role' => $user->role,
            'is_blocked' => (bool) $user->is_blocked,
            'created_at' => $user->created_at,
            'updated_at' => $user->updated_at,
        ];
    }

    private function transformPostImages(Post $post): Post
    {
        $post->images = $post->images->map(function ($img) {
            return [
                'id' => $img->id,
                'path' => $img->path,
                'url' => asset('storage/' . $img->path),
            ];
        });

        return $post;
    }

    // -------------------
    // Register
    // -------------------
    public function register(Request $request)
    {
        // Check if registration is open
        $regSetting = Setting::where('key', 'registration_open')->first();
        if ($regSetting && $regSetting->value === 'false') {
            return response()->json(['message' => 'Registration is closed'], 403);
        }

        $validated = $request->validate([
            'username' => 'required|unique:custom_users|max:255',
            'email' => 'required|email|unique:custom_users',
            'password' => 'required|min:8',
            'phone' => 'nullable|string',
        ]);

        $user = CustomUser::create([
            'username' => $validated['username'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'phone' => $request->phone,
            'role' => 'customer',
            'api_token' => Str::random(60)
        ]);

        return response()->json([
            'message' => 'User registered successfully',
            'token' => $user->api_token,
            'user' => $this->userPayload($user),
        ], 201);
    }

    // -------------------
    // Login
    // -------------------
    public function mee(Request $request)
    {
        $user = $this->authUser($request);
        if (!$user) {
            return null;
        }
        return response()->json($this->userPayload($user));
    }
    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required'
        ]);

        $user = CustomUser::where('email', $validated['email'])->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return response()->json(['message' => 'Invalid email or password'], 401);
       }
        if ($user->is_blocked) {
            return response()->json(['message' => 'Your account is blocked'], 403);
        }

        // Refresh token on login
        $user->api_token = Str::random(60);
        $user->save();

        return response()->json([
            'message' => 'Login successful',
            'token' => $user->api_token,
            'user' => $this->userPayload($user)
        ], 200);
    }

    // -------------------
    // Create Post (user/post)
    // -------------------
   public function userPost(Request $request)
{
    $user = $this->authUser($request);
    if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

    $validated = $request->validate([
        'category' => 'required',
        'type' => 'required',
        'amount' => 'required|numeric',
        'explanation' => 'nullable|string',
        'region' => 'required',
        'district' => 'required',
        'street' => 'nullable|string',
        'room_no' => 'nullable|string',
        'images' => 'nullable|array|max:3', // top-level array validation
        'images.*' => 'image|mimes:jpeg,png,jpg,gif,webp|max:2048' // each file max 2MB
    ]);

    // create post first
    $post = Post::create([
        'user_id' => $user->id,
        'poster' => $user->username,
        'category' => $validated['category'],
        'type' => $validated['type'],
        'amount' => $validated['amount'],
        'explanation' => $request->explanation,
        'region' => $validated['region'],
        'district' => $validated['district'],
        'street' => $request->street,
        'room_no' => $request->room_no,
        'status' => 'pending'
    ]);

    // handle images if present
    $storedImages = [];
    if ($request->hasFile('images')) {
        $files = $request->file('images');
        // enforce limit again (defensive)
        if (count($files) > 3) {
            return response()->json(['message' => 'You can upload a maximum of 3 images'], 422);
        }
        foreach ($files as $file) {
            $filename = time() . '_' . \Illuminate\Support\Str::random(8) . '.' . $file->getClientOriginalExtension();
            // store under storage/app/public/posts/{post_id}/
            $file->storeAs('public/posts/' . $post->id, $filename);
            $relativePath = 'posts/' . $post->id . '/' . $filename; // path stored in DB

            $pi = PostImage::create([
                'post_id' => $post->id,
                'path' => $relativePath,
            ]);

            // full accessible url (requires php artisan storage:link)
            $storedImages[] = asset('storage/' . $relativePath);
        }
    }

    // return post with images urls
    $post->load('images');

    $imagesUrls = $post->images->map(function ($img) {
        return asset('storage/' . $img->path);
    });

    return response()->json([
        'message' => 'Post created successfully',
        'post' => $post,
        'images' => $imagesUrls
    ], 201);
}


    // -------------------
    // Search House (user/search_house)
    // -------------------
   public function searchHouse(Request $request)
{
    $query = Post::query();

    if ($request->filled('category')) {
        $query->where('category', $request->category);
    }
    if ($request->filled('type')) {
        $query->where('type', $request->type);
    }
    if ($request->filled('region')) {
        $query->where('region', $request->region);
    }

    // Only paid/verified posts
    $query->where('status', 'paid');

        $posts = $query->with('images')->get();

        $posts->transform(function($post) {
        return $this->transformPostImages($post);
    });

    return response()->json([
        'count' => $posts->count(),
        'posts' => $posts
    ], 200);
}


    // -------------------
    // View posts by user (user/view_post/{id})
    // -------------------
   public function viewUserPosts($id)
{
    $posts = Post::with('images')->where('user_id', $id)->get();

    // convert images path to full URLs
    $posts->transform(function($post) {
        return $this->transformPostImages($post);
    });

    return response()->json([
        'count' => $posts->count(),
        'posts' => $posts
    ], 200);
}
   public function viewUserPostsone($id)
{
    $posts = Post::with('images')->where('id', $id)->get();
//  $posts = Post::where('id', $id)->get();
    // convert images path to full URLs
    $posts->transform(function($post) {
    return $this->transformPostImages($post);
    });

    return response()->json([
        'count' => $posts->count(),
        'posts' => $posts
    ], 200);
}

    // -------------------
    // Update profile (user/update_profile/{id})
    // -------------------
    public function updateProfile(Request $request, $id)
    {
        $actor = $this->authUser($request);
        if (!$actor) return response()->json(['message' => 'Unauthorized'], 401);

        $user = CustomUser::find($id);
        if (!$user) return response()->json(['message' => 'User not found'], 404);

        if ($actor->id !== $user->id && $actor->role !== 'admin') {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        // Validate username/email uniqueness if changed
        $rules = ['phone' => 'nullable|string'];
        if ($request->filled('username') && $request->username !== $user->username) {
            $rules['username'] = 'required|unique:custom_users,username';
        }
        if ($request->filled('email') && $request->email !== $user->email) {
            $rules['email'] = 'required|email|unique:custom_users,email';
        }
        if ($request->filled('password')) {
            $rules['password'] = 'nullable|min:8';
        }
        if ($actor->role === 'admin') {
            if ($request->filled('role')) {
                $rules['role'] = 'required|in:admin,customer';
            }
            if ($request->has('is_blocked')) {
                $rules['is_blocked'] = 'required|boolean';
            }
        } elseif ($request->has('role') || $request->has('is_blocked')) {
            return response()->json(['message' => 'Only admins can change role or block status'], 403);
        }
        $request->validate($rules);

        if ($request->filled('username')) $user->username = $request->username;
        if ($request->filled('email')) $user->email = $request->email;
        if ($request->has('phone')) $user->phone = $request->phone;
        if ($request->filled('password')) $user->password = Hash::make($request->password);
        if ($actor->role === 'admin') {
            if ($request->filled('role')) $user->role = $request->role;
            if ($request->has('is_blocked')) $user->is_blocked = $request->boolean('is_blocked');
        }

        $user->save();

        return response()->json([
            'message' => 'Profile updated successfully',
            'user' => $this->userPayload($user),
        ], 200);
    }

    // -------------------
    // Delete user (user/delete/{id})
    // -------------------
   public function deleteUser(Request $request, $id)
{
    $actor = $this->authUser($request);
    if (!$actor) return response()->json(['message' => 'Unauthorized'], 401);

    $user = CustomUser::find($id);
    if (!$user) return response()->json(['message' => 'User not found'], 404);

    if ($actor->id !== $user->id && $actor->role !== 'admin') {
        return response()->json(['message' => 'Forbidden'], 403);
    }

    if ($actor->role === 'admin' && $actor->id === $user->id) {
        return response()->json(['message' => 'Admins cannot delete their own account from this endpoint'], 422);
    }

    // delete post image folders for user's posts
    $posts = Post::where('user_id', $user->id)->get();
    foreach ($posts as $post) {
        // remove directory storage/app/public/posts/{post_id}
        Storage::deleteDirectory('public/posts/' . $post->id);
    }

    $user->delete();
    return response()->json(['message' => 'User deleted successfully'], 200);
}


    // -------------------
    // View profile (user/view_profile/{id})
    // -------------------
    public function viewProfile(Request $request, $id)
    {
        $actor = $this->authUser($request);
        if (!$actor) return response()->json(['message' => 'Unauthorized'], 401);

        $user = CustomUser::find($id);
        if (!$user) return response()->json(['message' => 'User not found'], 404);

        if ($actor->id !== $user->id && $actor->role !== 'admin') {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        return response()->json($this->userPayload($user), 200);
    }

    // -------------------
    // Agent: Create (agent/create)
    // -------------------
    public function createAgent(Request $request)
    {
        $user = $this->authUser($request);
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

        $validated = $request->validate([
            'agent_name' => 'required',
            'region' => 'required',
            'phone' => 'required',
        ]);

        $agent = Agent::updateOrCreate([
            'created_by' => $user->id,
        ], [
            'agent_name' => $validated['agent_name'],
            'region' => $validated['region'],
            'phone' => $validated['phone'],
            'status' => 'pending',
            'created_by' => $user->id,
        ]);

        return response()->json([
            'message' => $agent->wasRecentlyCreated
                ? 'Agent created successfully'
                : 'Agent request updated successfully',
            'agent' => $agent,
        ], $agent->wasRecentlyCreated ? 201 : 200);
    }

    // -------------------
    // Agent: View (agent/view/{id})
    // -------------------
    public function viewAgent($id)
    {
        $agent = Agent::find($id);
        if (!$agent && is_numeric($id)) {
            $agent = Agent::where('created_by', $id)->first();
        }
        if (!$agent) return response()->json(['message' => 'Agent not found'], 404);

        return response()->json($agent, 200);
    }

    // -------------------
    // Agent: Update (agent/update/{id})
    // -------------------
    public function updateAgent(Request $request, $id)
    {
        $user = $this->authUser($request);
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

        $agent = Agent::find($id);
        if (!$agent) return response()->json(['message' => 'Agent not found'], 404);

        if ($agent->created_by !== $user->id && $user->role !== 'admin') {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $request->validate([
            'agent_name' => 'nullable|string',
            'region' => 'nullable|string',
            'phone' => 'nullable|string',
            'status' => 'nullable|string',
        ]);

        $payload = $request->only(['agent_name', 'region', 'phone']);
        if ($user->role === 'admin' && $request->filled('status')) {
            $payload['status'] = $request->status;
        }

        $agent->update($payload);

        return response()->json(['message' => 'Agent updated successfully', 'agent' => $agent], 200);
    }

    // -------------------
    // Agent: Delete (agent/delete/{id})
    // -------------------
    public function deleteAgent(Request $request, $id)
    {
        $user = $this->authUser($request);
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

        $agent = Agent::find($id);
        if (!$agent) return response()->json(['message' => 'Agent not found'], 404);

        if ($agent->created_by !== $user->id && $user->role !== 'admin') {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $agent->delete();
        return response()->json(['message' => 'Agent deleted successfully'], 200);
    }

    // -------------------
    // Agent: Search by region (agent/search)
    // -------------------
    public function searchAgent(Request $request)
    {
        $request->validate(['region' => 'required']);
        $agents = Agent::where('region', $request->region)->get();

        return response()->json([
            'count' => $agents->count(),
            'agents' => $agents
        ], 200);
    }

    // -------------------
    // Admin: Verify Post -> set status to 'paid' (admin/verify_post/{id})
    // -------------------
    public function adminVerifyPost(Request $request, $postId)
    {
        $admin = $this->authUser($request);
        if (!$admin) return response()->json(['message' => 'Unauthorized'], 401);
        if ($admin->role !== 'admin') return response()->json(['message' => 'Forbidden'], 403);

        $post = Post::find($postId);
        if (!$post) return response()->json(['message' => 'Post not found'], 404);

        $post->status = 'paid';
        $post->save();

        return response()->json(['message' => 'Post verified and set to paid', 'post' => $post], 200);
    }

    public function adminDeletePost(Request $request, $id)
    {
        $admin = $this->authUser($request);
        if (!$admin) return response()->json(['message' => 'Unauthorized'], 401);
        if ($admin->role !== 'admin') return response()->json(['message' => 'Forbidden'], 403);

        $post = Post::find($id);
        if (!$post) return response()->json(['message' => 'Post not found'], 404);

        Storage::deleteDirectory('public/posts/' . $post->id);
        PostImage::where('post_id', $post->id)->delete();
        $post->delete();

        return response()->json(['message' => 'Post deleted'], 200);
    }

    // -------------------
    // Admin: View summary (admin/view)
    // -------------------
    public function adminView(Request $request)
    {
        $admin = $this->authUser($request);
        if (!$admin) return response()->json(['message' => 'Unauthorized'], 401);
        if ($admin->role !== 'admin') return response()->json(['message' => 'Forbidden'], 403);

        $usersCount = CustomUser::count();
        $agentsCount = Agent::count();
        $postsCount = Post::count();
        $registrationSetting = Setting::where('key', 'registration_open')->first();
        $registrationOpen = !$registrationSetting || $registrationSetting->value !== 'false';

        return response()->json([
            'users_count' => $usersCount,
            'agents_count' => $agentsCount,
            'posts_count' => $postsCount,
            'registration_open' => $registrationOpen,
            'pending_posts_count' => Post::where('status', '!=', 'paid')->count(),
            'pending_agents_count' => Agent::where('status', '!=', 'paid')->count(),
            'open_reports_count' => Report::where('status', 'open')->count(),
            'blocked_users_count' => CustomUser::where('is_blocked', true)->count(),
        ], 200);
    }

    // -------------------
    // Admin: Close/Open registration (admin/close_registration)
    // -------------------
    // Expects 'open' => true/false in body
    public function adminCloseRegistration(Request $request)
    {
        $admin = $this->authUser($request);
        if (!$admin) return response()->json(['message' => 'Unauthorized'], 401);
        if ($admin->role !== 'admin') return response()->json(['message' => 'Forbidden'], 403);

        $request->validate(['open' => 'required|boolean']);

        $setting = Setting::firstOrNew(['key' => 'registration_open']);
        $setting->value = $request->open ? 'true' : 'false';
        $setting->save();

        return response()->json(['message' => 'Registration setting updated', 'registration_open' => $setting->value], 200);
    }

    // -------------------
    // Admin: View paid posts (admin/view_paid_posts)
    // -------------------
    public function adminViewPaidPosts(Request $request)
    {
        $admin = $this->authUser($request);
        if (!$admin) return response()->json(['message' => 'Unauthorized'], 401);
        if ($admin->role !== 'admin') return response()->json(['message' => 'Forbidden'], 403);

        $posts = Post::where('status', 'paid')->get();
        return response()->json(['count' => $posts->count(), 'posts' => $posts], 200);
    }

    // -------------------
    // Admin: View unpaid/pending agents (admin/view_unpaid_agents)
    // -------------------
    public function adminViewUnpaidAgents(Request $request)
    {
        $admin = $this->authUser($request);
        if (!$admin) return response()->json(['message' => 'Unauthorized'], 401);
        if ($admin->role !== 'admin') return response()->json(['message' => 'Forbidden'], 403);

        // Agents that are not verified
        $agents = Agent::where('status', '!=', 'paid')->get();
        return response()->json(['count' => $agents->count(), 'agents' => $agents], 200);
    }

    // -------------------
    // Admin: Verify Agent (admin/verify_agent/{id})
    // -------------------
    public function adminVerifyAgent(Request $request, $agentId)
    {
        $admin = $this->authUser($request);
        if (!$admin) return response()->json(['message' => 'Unauthorized'], 401);
        if ($admin->role !== 'admin') return response()->json(['message' => 'Forbidden'], 403);

        $agent = Agent::find($agentId);
        if (!$agent) return response()->json(['message' => 'Agent not found'], 404);

        $agent->status = 'paid';
        $agent->save();

        return response()->json(['message' => 'Agent verified', 'agent' => $agent], 200);
    }

    // -------------------
    // Admin: Delete Agent (admin/delete_agent/{id})
    // -------------------
    public function adminDeleteAgent(Request $request, $id)
    {
        $admin = $this->authUser($request);
        if (!$admin) return response()->json(['message' => 'Unauthorized'], 401);
        if ($admin->role !== 'admin') return response()->json(['message' => 'Forbidden'], 403);

        $agent = Agent::find($id);
        if (!$agent) return response()->json(['message' => 'Agent not found'], 404);

        $agent->delete();
        return response()->json(['message' => 'Agent deleted'], 200);
    }

    // -------------------
    // Reporting: report agent (report/agent)
    // -------------------
    public function reportAgent(Request $request)
    {
        $reporter = $this->authUser($request);
        if (!$reporter) return response()->json(['message' => 'Unauthorized'], 401);

        $validated = $request->validate([
            'agent_id' => 'required|exists:agents,id',
            'reason' => 'nullable|string',
            'details' => 'nullable|string',
        ]);

        $report = Report::create([
            'reporter_id' => $reporter->id,
            'report_type' => 'agent',
            'reported_id' => $validated['agent_id'],
            'reason' => $request->reason,
            'details' => $request->details,
            'status' => 'open',
        ]);

        return response()->json(['message' => 'Agent reported', 'report' => $report], 201);
    }

    // -------------------
    // Reporting: report post (report/post)
    // -------------------
    public function reportPost(Request $request)
    {
        $reporter = $this->authUser($request);
        if (!$reporter) return response()->json(['message' => 'Unauthorized'], 401);

        $validated = $request->validate([
            'post_id' => 'required|exists:posts,id',
            'reason' => 'nullable|string',
            'details' => 'nullable|string',
        ]);

        $report = Report::create([
            'reporter_id' => $reporter->id,
            'report_type' => 'post',
            'reported_id' => $validated['post_id'],
            'reason' => $request->reason,
            'details' => $request->details,
            'status' => 'open',
        ]);

        return response()->json(['message' => 'Post reported', 'report' => $report], 201);
    }

    // -------------------
    // Admin: View Reports (admin/view_reports)
    // -------------------
    public function adminViewReports(Request $request)
    {
        $admin = $this->authUser($request);
        if (!$admin) return response()->json(['message' => 'Unauthorized'], 401);
        if ($admin->role !== 'admin') return response()->json(['message' => 'Forbidden'], 403);

        $reports = Report::orderBy('created_at', 'desc')->get();

        // Enrich with reporter and reported entity
        $result = $reports->map(function ($r) {
            $reported = null;
            if ($r->report_type === 'post') {
                $reported = Post::find($r->reported_id);
            } elseif ($r->report_type === 'agent') {
                $reported = Agent::find($r->reported_id);
            }
            $reporter = CustomUser::find($r->reporter_id);

            return [
                'report' => $r,
                'reporter' => $reporter ? $this->userPayload($reporter) : null,
                'reported' => $reported
            ];
        });

        return response()->json(['count' => $result->count(), 'reports' => $result], 200);
    }

    public function adminDeleteReport(Request $request, $id)
    {
        $admin = $this->authUser($request);
        if (!$admin) return response()->json(['message' => 'Unauthorized'], 401);
        if ($admin->role !== 'admin') return response()->json(['message' => 'Forbidden'], 403);

        $report = Report::find($id);
        if (!$report) return response()->json(['message' => 'Report not found'], 404);

        $report->delete();

        return response()->json(['message' => 'Report deleted'], 200);
    }
    public function updateUserPost(Request $request, $id)
{
    $user = $this->authUser($request);
    if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

    $post = Post::find($id);
    if (!$post) return response()->json(['message' => 'Post not found'], 404);

    // Only owner or admin can update
    if ($post->user_id !== $user->id && $user->role !== 'admin') {
        return response()->json(['message' => 'Forbidden'], 403);
    }

    $validated = $request->validate([
        'category' => 'nullable|string',
        'type' => 'nullable|string',
        'amount' => 'nullable|numeric',
        'explanation' => 'nullable|string',
        'region' => 'nullable|string',
        'district' => 'nullable|string',
        'street' => 'nullable|string',
        'room_no' => 'nullable|string',
        'status' => 'nullable|string',
        'images' => 'nullable|array|max:3',
        'images.*' => 'image|mimes:jpeg,png,jpg,gif,webp|max:2048'
    ]);

    $post->fill($request->only(['category','type','amount','explanation','region','district','street','room_no','status']));
    $post->save();

    // If images provided, replace current images
    if ($request->hasFile('images')) {
        // delete old files
        Storage::deleteDirectory('public/posts/' . $post->id);
        PostImage::where('post_id', $post->id)->delete();

        $files = $request->file('images');
        foreach ($files as $file) {
            $filename = time().'_'.Str::random(8).'.'.$file->getClientOriginalExtension();
            $file->storeAs('public/posts/'.$post->id, $filename);
            $relativePath = 'posts/'.$post->id.'/'.$filename;
            PostImage::create(['post_id'=>$post->id,'path'=>$relativePath]);
        }
    }

    $post->load('images');
    $this->transformPostImages($post);

    return response()->json(['message'=>'Post updated','post'=>$post], 200);
}

public function deleteUserPost(Request $request, $id)
{
    $user = $this->authUser($request);
    if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

    $post = Post::find($id);
    if (!$post) return response()->json(['message' => 'Post not found'], 404);

    // Only owner or admin can delete
    if ($post->user_id !== $user->id && $user->role !== 'admin') {
        return response()->json(['message' => 'Forbidden'], 403);
    }

    // delete images folder
    Storage::deleteDirectory('public/posts/'.$post->id);

    $post->delete();

    return response()->json(['message' => 'Post deleted'], 200);
}
public function listAgentsPublic()
{
    $agents = Agent::where('status','paid')->get(); // only verified agents public
    return response()->json(['count'=>$agents->count(),'agents'=>$agents], 200);
}

// public function storeContact(Request $request)
// {
//     $validated = $request->validate([
//         'name' => 'required|string',
//         'email' => 'nullable|email',
//         'subject' => 'nullable|string',
//         'message' => 'nullable|string',
//     ]);

//     $user = $this->authUser($request);

//     $contact = Contact::create([
//         'name' => $validated['name'],
//         'email' => $validated['email'] ?? null,
//         'subject' => $validated['subject'] ?? null,
//         'message' => $validated['message'] ?? null,
//         'user_id' => $user ? $user->id : null
//     ]);

//     return response()->json(['message'=>'Contact stored','contact'=>$contact], 201);
// }
// public function viewContacts(Request $request)
// {
//     $admin = $this->authUser($request);
//     if (!$admin) return response()->json(['message' => 'Unauthorized'], 401);
//     if ($admin->role !== 'admin') return response()->json(['message' => 'Forbidden'], 403);

//     $contacts = Contact::orderBy('created_at','desc')->get();
//     return response()->json(['count'=>$contacts->count(),'contacts'=>$contacts], 200);
// }

public function viewContact(Request $request, $id)
{
    $admin = $this->authUser($request);
    if (!$admin) return response()->json(['message' => 'Unauthorized'], 401);
    if ($admin->role !== 'admin') return response()->json(['message' => 'Forbidden'], 403);

    $contact = Contact::find($id);
    if (!$contact) return response()->json(['message'=>'Contact not found'], 404);
    return response()->json($contact, 200);
}

public function unpaidPosts(Request $request)
{
    $admin = $this->authUser($request);
    if (!$admin) return response()->json(['message'=>'Unauthorized'], 401);
    if ($admin->role !== 'admin') return response()->json(['message'=>'Forbidden'], 403);

    $posts = Post::where('status','!=','paid')->with('images')->get();
    $posts->transform(fn($post) => $this->transformPostImages($post));
    return response()->json(['count'=>$posts->count(),'posts'=>$posts], 200);
}
public function viewAllUsers(Request $request)
{
    $admin = $this->authUser($request);
    if (!$admin) return response()->json(['message'=>'Unauthorized'], 401);
    if ($admin->role !== 'admin') return response()->json(['message'=>'Forbidden'], 403);

    $users = CustomUser::all()->map(fn($user) => $this->userPayload($user));
    return response()->json(['count'=>$users->count(),'users'=>$users], 200);
}
public function blockUser(Request $request, $id)
{
    $admin = $this->authUser($request);
    if (!$admin) return response()->json(['message'=>'Unauthorized'], 401);
    if ($admin->role !== 'admin') return response()->json(['message'=>'Forbidden'], 403);

    $request->validate(['block' => 'required|boolean']); // true = block, false = unblock

    $user = CustomUser::find($id);
    if (!$user) return response()->json(['message'=>'User not found'], 404);

    if ($admin->id === $user->id && $request->boolean('block')) {
        return response()->json(['message' => 'Admins cannot block themselves'], 422);
    }

    $user->is_blocked = $request->block;
    $user->save();

    return response()->json([
        'message'=> $user->is_blocked ? 'User blocked' : 'User unblocked',
        'user' => $this->userPayload($user),
    ], 200);
}
public function viewAllPostsPublic()
{
    $posts = Post::where('status','paid')->with('images','user')->orderBy('created_at','desc')->get();
    $posts->transform(fn($post) => $this->transformPostImages($post));
    return response()->json(['count'=>$posts->count(),'posts'=>$posts], 200);
}
// send message
// public function sendMessage(Request $request)
// {
//     $sender = $this->authUser($request);
//     if (!$sender) return response()->json(['message'=>'Unauthorized'], 401);

//     $validated = $request->validate([
//         'receiver_id' => 'required|exists:custom_users,id',
//         'message' => 'required|string',
//     ]);

//     // prevent sending to blocked user
//     $receiver = CustomUser::find($validated['receiver_id']);
//     if ($receiver->is_blocked) {
//         return response()->json(['message'=>'Cannot send message to this user'], 403);
//     }

//     $msg = Message::create([
//         'sender_id' => $sender->id,
//         'receiver_id' => $validated['receiver_id'],
//         'message' => $validated['message'],
//         'is_read' => false
//     ]);

//     return response()->json(['message'=>'Message sent','data'=>$msg], 201);
// }

// get conversation between auth user and another user
// public function getConversation(Request $request, $otherUserId)
// {
//     $user = $this->authUser($request);
//     if (!$user) return response()->json(['message'=>'Unauthorized'], 401);

//     $other = CustomUser::find($otherUserId);
//     if (!$other) return response()->json(['message'=>'User not found'], 404);

//     $msgs = Message::where(function($q) use ($user, $otherUserId) {
//         $q->where('sender_id', $user->id)->where('receiver_id', $otherUserId);
//     })->orWhere(function($q) use ($user, $otherUserId) {
//         $q->where('sender_id', $otherUserId)->where('receiver_id', $user->id);
//     })->orderBy('created_at','asc')->get();

//     // mark messages received by auth user as read
//     Message::where('sender_id', $otherUserId)
//         ->where('receiver_id', $user->id)
//         ->where('is_read', false)
//         ->update(['is_read' => true]);

//     return response()->json(['count'=>$msgs->count(),'messages'=>$msgs], 200);
// }

// list conversations for authenticated user (distinct partners + last message)
// public function listConversations(Request $request)
// {
//     $user = $this->authUser($request);
//     if (!$user) return response()->json(['message'=>'Unauthorized'], 401);

//     // get last message per conversation partner (simple approach)
//     $conversations = DB::table('messages')
//         ->select(DB::raw('
//             CASE 
//                 WHEN sender_id = '.$user->id.' THEN receiver_id 
//                 ELSE sender_id 
//             END as partner_id,
//             MAX(created_at) as last_time
//         '))
//         ->where('sender_id', $user->id)
//         ->orWhere('receiver_id', $user->id)
//         ->groupBy('partner_id')
//         ->orderBy('last_time', 'desc')
//         ->get();

//     $result = $conversations->map(function($c) use ($user) {
//         $partner = CustomUser::find($c->partner_id);
//         $last = Message::where(function($q) use ($user, $c) {
//             $q->where('sender_id', $user->id)->where('receiver_id', $c->partner_id);
//         })->orWhere(function($q) use ($user, $c) {
//             $q->where('sender_id', $c->partner_id)->where('receiver_id', $user->id);
//         })->orderBy('created_at','desc')->first();

//         return [
//             'partner' => $partner,
//             'last_message' => $last
//         ];
//     });

//     return response()->json(['count'=>$result->count(),'conversations'=>$result], 200);
// }
public function toggleLike(Request $request, $postId)
{
    $user = $this->authUser($request);
    if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

    // ensure post exists
    $post = Post::find($postId);
    if (!$post) {
        return response()->json(['message' => 'Post not found'], 404);
    }

    try {
        $existing = Like::where('user_id', $user->id)->where('post_id', $postId)->first();

        if ($existing) {
            $existing->delete();
            $count = Like::where('post_id', $postId)->count();
            return response()->json([
                'message' => 'Unliked',
                'count' => $count,
                'liked_by_me' => false,
            ], 200);
        } else {
            $like = Like::create(['user_id' => $user->id, 'post_id' => $postId]);
            $count = Like::where('post_id', $postId)->count();
            return response()->json([
                'message' => 'Liked',
                'like' => $like,
                'count' => $count,
                'liked_by_me' => true,
            ], 201);
        }
    } catch (\Throwable $e) {
        \Log::error('toggleLike error: '.$e->getMessage());
        return response()->json(['message' => 'Server error', 'error' => $e->getMessage()], 500);
    }
}

public function getLikes(Request $request, $postId)
{
    // if post missing, return zero rather than error
    $postExists = Post::where('id', $postId)->exists();
    if (!$postExists) {
        return response()->json(['count' => 0, 'users' => []], 200);
    }

    try {
        $count = Like::where('post_id', $postId)->count();
        // return likes with the user relation (user() defined on Like model)
        $likes = Like::where('post_id', $postId)->with('user:id,username,email')->get();

        // determine liked_by_me if caller provided token
        $currentUser = $this->authUser($request);
        $likedByMe = false;
        if ($currentUser) {
            $likedByMe = Like::where('post_id', $postId)->where('user_id', $currentUser->id)->exists();
        }

        return response()->json([
            'count' => $count,
            'likes' => $likes,
            'liked_by_me' => $likedByMe,
        ], 200);
    } catch (\Throwable $e) {
        \Log::error('getLikes error: '.$e->getMessage());
        return response()->json(['count' => 0, 'likes' => [], 'error' => $e->getMessage()], 500);
    }
}

public function addComment(Request $request, $postId)
{
    $user = $this->authUser($request);
    if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

    $post = Post::find($postId);
    if (!$post) {
        return response()->json(['message' => 'Post not found'], 404);
    }

    $validated = $request->validate([
        'content' => 'required|string',
    ]);

    try {
        $comment = Comment::create([
            'user_id' => $user->id,
            'post_id' => $postId,
            'content' => $validated['content'],
        ]);

        // load the user relation so frontend gets username/email
        // $comment->load('user:id,username,email');
         $comment = Comment::where('id', $comment->id)->first();

        return response()->json(['message' => 'Comment added', 'comment' => $comment], 201);
    } catch (\Throwable $e) {
        \Log::error('addComment error: '.$e->getMessage());
        return response()->json(['message' => 'Failed to add comment', 'error' => $e->getMessage()], 500);
    }
}

public function getComments($postId)
{
    // if post missing, return empty list
    $postExists = Post::where('id', $postId)->exists();
    if (!$postExists) {
        return response()->json(['count' => 0, 'comments' => []], 200);
    }

    try {
        $comments = Comment::where('post_id', $postId)
            ->with('user:id,username,email')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['count' => $comments->count(), 'comments' => $comments], 200);
    } catch (\Throwable $e) {
        \Log::error('getComments error: '.$e->getMessage());
        return response()->json(['count' => 0, 'comments' => [], 'error' => $e->getMessage()], 500);
    }
}



}
