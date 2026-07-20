import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!

    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    })

    const authHeader = req.headers.get("Authorization")!
    const token = authHeader.replace("Bearer ", "")

    const {
      data: { user: adminUser },
      error: authError,
    } = await supabase.auth.getUser(token)

    if (authError || !adminUser) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const { data: adminProfile } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", adminUser.id)
      .single()

    if (!adminProfile || adminProfile.role !== "administrator") {
      return new Response(
        JSON.stringify({ error: "Only administrators can create users" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const {
      email,
      firstName,
      lastName,
      role,
      phone,
      department,
      employeeId,
      qualification,
      hireDate,
      parentIds,
      relationship,
    } = await req.json()

    if (!email || !firstName || !lastName || !role) {
      return new Response(
        JSON.stringify({ error: "email, firstName, lastName, and role are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    if (!["teacher", "parent"].includes(role)) {
      return new Response(
        JSON.stringify({ error: "role must be 'teacher' or 'parent'" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const { data: authUser, error: createError } =
      await supabase.auth.admin.inviteUserByEmail(email, {
        data: { first_name: firstName, last_name: lastName },
      })

    if (createError) {
      return new Response(
        JSON.stringify({ error: createError.message }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const { error: profileError } = await supabase.from("profiles").insert({
      id: authUser.user.id,
      email,
      first_name: firstName,
      last_name: lastName,
      role,
      phone: phone || null,
      created_by: adminUser.id,
    })

    if (profileError) {
      await supabase.auth.admin.deleteUser(authUser.user.id)
      return new Response(
        JSON.stringify({ error: `Profile creation failed: ${profileError.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    if (role === "teacher") {
      if (!employeeId) {
        await supabase.auth.admin.deleteUser(authUser.user.id)
        return new Response(
          JSON.stringify({ error: "employeeId is required for teachers" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        )
      }

      const { error: teacherError } = await supabase.from("teachers").insert({
        profile_id: authUser.user.id,
        employee_id: employeeId,
        department: department || null,
        qualification: qualification || null,
        hire_date: hireDate || null,
        created_by: adminUser.id,
      })

      if (teacherError) {
        await supabase.auth.admin.deleteUser(authUser.user.id)
        return new Response(
          JSON.stringify({ error: `Teacher creation failed: ${teacherError.message}` }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        )
      }
    }

    if (role === "parent" && parentIds && parentIds.length > 0) {
      const studentRecords = await supabase
        .from("students")
        .select("id")
        .in("id", parentIds)

      if (studentRecords.data) {
        const links = studentRecords.data.map((s) => ({
          parent_id: authUser.user.id,
          student_id: s.id,
          relationship: relationship || "guardian",
          created_by: adminUser.id,
        }))

        await supabase.from("parent_students").insert(links)
      }
    }

    return new Response(
      JSON.stringify({
        message: "User created successfully",
        userId: authUser.user.id,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})
