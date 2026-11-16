import argparse
import json

from .corpus import compile_corpus, read_json, write_artifact


def main():
    parser = argparse.ArgumentParser(description="Build a reviewed FirstAid corpus atomically")
    parser.add_argument("input", help="Reviewed library or backend public snapshot JSON")
    parser.add_argument("output", help="Corpus artifact path")
    args = parser.parse_args()
    artifact = compile_corpus(read_json(args.input))
    write_artifact(artifact, args.output)
    print(json.dumps({"corpus_version": artifact["corpus_version"],
                      "document_count": len(artifact["documents"])}))


if __name__ == "__main__":
    main()
