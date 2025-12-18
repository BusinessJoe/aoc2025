import sys
import requests


def get_input(day, session_cookie):
    return requests.get(f'https://adventofcode.com/2025/day/{day}/input',
                        cookies={'session': session_cookie}).text


def main():
    session_cookie = sys.argv[1]
    for day in range(1, 13):
        day_input = get_input(day, session_cookie).encode(encoding="ascii")

        with open(f'./real/{day}', 'wb') as f:
            f.write(day_input)


if __name__ == '__main__':
    main()
