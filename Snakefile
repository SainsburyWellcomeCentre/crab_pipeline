from snakemake.utils import min_version
min_version("6.0")

configfile: "config.yaml"



SESSION, CAMERA, VIDEO_NAMES, = glob_wildcards(config['raw_path'] + "/{session}/cam{camera}/{rawmov}.MOV")

rule all:
    input:
        config['processed_path'] + "/metadata_csv/movie_paths.csv",
        # expand(config['processed_path'] + "/videos/{session}_cam{camera}_{rawmov}.mp4", session=SESSION, camera=CAMERA, rawmov=VIDEO_NAMES)



rule convert_mov_to_mp4:
    input:
        video = config['raw_path'] + "/{session}/cam{camera,[0-9]}/{rawmov}.MOV"
    output:
        config['processed_path'] + "/videos/{session}_cam{camera,[0-9]}_{rawmov}.mp4"
    log:
        config['processed_path'] + "/videos/log/{session}_cam{camera,[0-9]}_{rawmov}.log"
    conda:
        "tools/ffmpeg/environment.yml"
    container:
        "docker://jrottenberg/ffmpeg:3-alpine"
    shell:
        "ffmpeg -i {input.video} {output} 2> {log}"


rule extract_metadata:
    input:
        config['raw_path'] + "/{session}/cam{camera}/{rawmov}.MOV"
    output:
        config['processed_path'] + "/metadata_jsons/{session}_cam-{camera}_mov-{rawmov}.json"
    conda:
        "scripts/extract_metadata_hachoir/environment.yml"
    shell:
        "python scripts/extract_metadata_hachoir/main.py --camera {wildcards.camera} --session {wildcards.session} {input} > {output}"


# rule extract_metadata2:
#     input:
#         config['raw_path'] + "/{session}/cam{camera}/{rawmov}.MOV"
#     output:
#         config['processed_path'] + "/metadata_ffprobe_jsons/{session}_cam-{camera}_mov-{rawmov}.json"
#     conda:
#         "scripts/extract_metadata_ffprobe/environment.yml"
#     shell:
#         "python scripts/extract_metadata_ffprobe/main.py --camera {wildcards.camera} --session {wildcards.session} {input} > {output}"


rule merge_metadata_to_csv:
    input:
        expand(config['processed_path'] + "/metadata_jsons/{session}_cam-{camera}_mov-{rawmov}.json", zip, session=SESSION, camera=CAMERA, rawmov=VIDEO_NAMES)
    output:
        config['processed_path'] + "/metadata_csv/movie_paths.csv"
    conda:
        "scripts/join_metadata_to_csv/environment.yml"
    script:
        "scripts/join_metadata_to_csv/main.py"
    
  


### Utility Rules

rule build_singularity_image_file:
    input:
        "envs/{recipe}/{recipe}.def"
    output:
        "{recipe}.sif"
    shell:
        "singularity build --fakeroot {output} {input}"