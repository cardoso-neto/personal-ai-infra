---
description: Distill knowledge from source files into target file with merge conflicts
argument-hint: [source-file-1] [source-file-2] ... [target-file]
---

Perform a knowledge distillation task.
The user provided one or more source files and a target file:

- All files EXCEPT the last one are SOURCE files from which to extract knowledge
- The LAST file is the TARGET file where distilled knowledge should be merged

Arguments provided: $ARGUMENTS

INSTRUCTIONS:

1. **Read all files**
   - Read the current contents of the target file
   - Read all source files

2. **Analyze and distill**:
   - Extract key knowledge and information from the source files
   - Identify what information would enhance the target file
   - Synthesize the knowledge into something that fits the target's structure style
   - Avoid duplicating information already well-covered in target

3. **Generate merge with conflict markers**:
   - Use git merge conflict syntax to present changes
   - Format for EACH proposed change:
     ```
     <<<<<<< CURRENT (target-filename)
     [existing content from target file, or empty if new section]
     =======
     [proposed new/modified content with distilled knowledge]
     >>>>>>> DISTILLED (from: source-file-1, source-file-2, ...)
     ```
   - Prefer smaller focused conflict blocks

Reminders:

- Quality over quantity - distill and coalesce, don't just copy
- Preserve the target file's voice and patterns
- Make each conflict block focused on one coherent change
- Add source attribution in conflict marker to show where knowledge came from

After writing the file, provide a summary of what knowledge was distilled.
The user will then manually review and resolve each conflict block to accept or reject changes.
