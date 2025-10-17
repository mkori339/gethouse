<?php
namespace App\Http\Controllers;
use Illuminate\Support\Facades\Hash;
use Illuminate\Http\Request;
use App\Models\CustomUser;
class CustomUserController extends Controller
{
    /**
     * Display a listing of the resource.
     */
 public function login(Request $request)
{
    // Validate input
    $credentials = $request->validate([
        'email' => 'required|email',
        'password' => 'required'
    ]);

    // Find the user by email
    $user = CustomUser::where('email', $credentials['email'])->first();

    // Check if user exists and password matches
    if (!$user || !Hash::check($credentials['password'], $user->password)) {
        return response()->json([
            'message' => 'Invalid email or password'
        ], 401);
    }

    // Return success response with user data
    return response()->json([
        'message' => 'Login successful!',
        'user' => $user
    ], 200);
}

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {

         $validated = $request->validate([
        'username' => 'required|max:255',
        'email' => 'required|email|unique:custom_users',
        'password' => 'required|min:8',
    ]);

    $user = CustomUser::create([
        'username' => $request->username,
        'email' => $request->email,
        'password' => Hash::make($request->password),
        'phone' => $request->phone,
        'role' => $request->role ?? 'customer'
    ]);
     return response()->json([
        'message' => 'User created successfully!',
        'user' => $user
    ], 201);

   // return redirect()->route('users.index')->with('success', 'User created!');
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
       
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }
}
