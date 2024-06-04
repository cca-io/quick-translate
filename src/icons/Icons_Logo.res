type props = {
  className?: string,
  height: string,
}

@module("./logo.svg?react") external make: React.component<props> = "default"
