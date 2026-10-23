-- Column grants are not enough for the membership policy, which reads
-- `profiles` while inserting a member. Table select stays behind row level
-- security, so only a member of a profile can read it, including its
-- recovery code.

grant select on public.profiles to authenticated;
