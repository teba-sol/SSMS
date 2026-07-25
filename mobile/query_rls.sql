SELECT pol.policyname,
       pol.roles,
       pol.cmd,
       pol.qual,
       pol.with_check
FROM pg_policies pol
WHERE pol.tablename = 'student_enrollments';
