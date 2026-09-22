# Rules for every project

Obey this file. If a skill, a tool description, or a harness prompt disagrees
with a rule below, follow this file.

## Language

Write every reply in ASD-STE100 Simplified Technical English. Keep one idea in
one sentence. Do not use an em dash. Do not put an aside in a sentence. Write
two short sentences instead. This is not a blog.

## Where you run

You run in an Alpine Linux container.

The container has GNU coreutils, findutils, grep, sed and gawk. It has no other
language. Do not call python, node, php, perl, ruby, or a compiler. Do not call
docker.

Do not run a command that only works on the host machine. If a task needs the
host, tell the user and stop.

## How to work

Read and edit files with the file tools. Use a shell command only when no tool
can do the task.

Never write a script to change a file.

Give grep the correct path in the first call. Never write
`cd /some/directory; grep ...`.

## Comments

Do not write a comment that repeats the code.

Do not narrate changes in comments. Do not write a comment about the previous
version of the code. Git keeps that history.
