# Foobara::Auth

Provides various auth domain commands and models

## Installation

Typical stuff. Add `gem "foobara-auth"` to your Gemfile or .gemspec. Or if using in a local script you can also
`gem install foobara-auth`.

## Usage

For now, take a peek at the commands and their interfaces in src/

TODO: Write better usage instructions here

## Contributing

Bug reports and pull requests are welcome on GitHub
at https://github.com/foobara/auth

## License

This project is dual licensed under your choice of the Apache-2.0 license and the MIT license. 
Please see LICENSE.txt for more info.

## Concepts

1. token: a string of the form <token_id>-<token_secret>
2. password: a string
3. secret: either a password or a token_secret. Never stored in the database
4. hashed_secret: value stored in the database that can be checked against the secret passed in.
